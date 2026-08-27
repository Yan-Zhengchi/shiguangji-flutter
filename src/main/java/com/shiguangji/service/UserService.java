package com.shiguangji.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shiguangji.common.BizException;
import com.shiguangji.common.ErrorCode;
import com.shiguangji.dto.ProfileUpdateRequest;
import com.shiguangji.dto.ProfileVO;
import com.shiguangji.entity.FamilyMember;
import com.shiguangji.entity.Favorite;
import com.shiguangji.entity.Recipe;
import com.shiguangji.entity.User;
import com.shiguangji.mapper.FamilyMemberMapper;
import com.shiguangji.mapper.FavoriteMapper;
import com.shiguangji.mapper.RecipeMapper;
import com.shiguangji.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * 个人页：资料 + 统计（菜谱数/收藏数/家庭数）
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final RecipeMapper recipeMapper;
    private final FavoriteMapper favoriteMapper;
    private final FamilyMemberMapper familyMemberMapper;

    public ProfileVO profile(long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        ProfileVO vo = new ProfileVO();
        vo.setUserId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setNickname(user.getNickname());
        vo.setPhone(user.getPhone());
        vo.setAvatarUrl(user.getAvatarUrl());

        ProfileVO.Stats stats = new ProfileVO.Stats();
        stats.setRecipeCount(recipeMapper.selectCount(
                new LambdaQueryWrapper<Recipe>().eq(Recipe::getUserId, userId)));
        stats.setFavoriteCount(favoriteMapper.selectCount(
                new LambdaQueryWrapper<Favorite>().eq(Favorite::getUserId, userId)));
        stats.setFamilyCount(familyMemberMapper.selectCount(
                new LambdaQueryWrapper<FamilyMember>().eq(FamilyMember::getUserId, userId)));
        vo.setStats(stats);
        return vo;
    }

    public ProfileVO update(long userId, ProfileUpdateRequest req) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        if (req.getNickname() != null && !req.getNickname().isBlank()) {
            user.setNickname(req.getNickname());
        }
        if (req.getPhone() != null) {
            user.setPhone(req.getPhone());
        }
        if (req.getAvatarUrl() != null) {
            user.setAvatarUrl(req.getAvatarUrl());
        }
        userMapper.updateById(user);
        return profile(userId);
    }
}
