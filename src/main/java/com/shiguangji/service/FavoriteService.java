package com.shiguangji.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shiguangji.common.BizException;
import com.shiguangji.common.ErrorCode;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.entity.Favorite;
import com.shiguangji.entity.Recipe;
import com.shiguangji.mapper.FavoriteMapper;
import com.shiguangji.mapper.RecipeMapper;
import com.shiguangji.util.RedisCache;
import com.shiguangji.util.RedisKeys;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 收藏：DB 行 + Redis 计数器（定时回写 MySQL，避免高频行锁）
 */
@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteMapper favoriteMapper;
    private final RecipeMapper recipeMapper;
    private final StringRedisTemplate redis;
    private final RedisCache redisCache;

    @Transactional
    public void favorite(long userId, long recipeId) {
        Recipe recipe = recipeMapper.selectById(recipeId);
        if (recipe == null) {
            throw new BizException(ErrorCode.RECIPE_NOT_FOUND);
        }
        Long exists = favoriteMapper.selectCount(new LambdaQueryWrapper<Favorite>()
                .eq(Favorite::getUserId, userId).eq(Favorite::getRecipeId, recipeId));
        if (exists != null && exists > 0) {
            throw new BizException(ErrorCode.ALREADY_FAVORITED);
        }
        try {
            favoriteMapper.insert(newFavorite(userId, recipeId));
        } catch (DuplicateKeyException e) {
            throw new BizException(ErrorCode.ALREADY_FAVORITED);
        }
        redis.opsForValue().increment(RedisKeys.COUNTER_FAVORITE + recipeId);
        redis.opsForSet().add(RedisKeys.COUNTER_PENDING, String.valueOf(recipeId));
        redisCache.delete(RedisKeys.RECIPE_DETAIL + recipeId);
    }

    @Transactional
    public void unfavorite(long userId, long recipeId) {
        int deleted = favoriteMapper.delete(new LambdaQueryWrapper<Favorite>()
                .eq(Favorite::getUserId, userId).eq(Favorite::getRecipeId, recipeId));
        if (deleted > 0) {
            redis.opsForValue().decrement(RedisKeys.COUNTER_FAVORITE + recipeId);
            redisCache.delete(RedisKeys.RECIPE_DETAIL + recipeId);
        }
    }

    public List<RecipeCardVO> list(long userId, int page, int size) {
        int p = Math.max(page, 1);
        int s = size <= 0 ? 10 : Math.min(size, 50);
        List<RecipeCardVO> list = favoriteMapper.selectFavoriteCards(userId, (p - 1) * s, s);
        if (list != null) {
            for (RecipeCardVO vo : list) {
                long id = vo.getId() == null ? 0 : vo.getId();
                vo.setImgRatio(0.75 + Math.floorMod(id, 20) * 0.025);
            }
        }
        return list;
    }

    private Favorite newFavorite(long userId, long recipeId) {
        Favorite favorite = new Favorite();
        favorite.setUserId(userId);
        favorite.setRecipeId(recipeId);
        return favorite;
    }
}
