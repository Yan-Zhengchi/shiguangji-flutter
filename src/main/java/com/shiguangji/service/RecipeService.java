package com.shiguangji.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.shiguangji.common.BizException;
import com.shiguangji.common.ErrorCode;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.dto.RecipeDetailVO;
import com.shiguangji.dto.RecipePublishRequest;
import com.shiguangji.entity.Category;
import com.shiguangji.entity.Favorite;
import com.shiguangji.entity.Ingredient;
import com.shiguangji.entity.Recipe;
import com.shiguangji.entity.RecipeImage;
import com.shiguangji.entity.RecipeStep;
import com.shiguangji.entity.RecipeTool;
import com.shiguangji.entity.Tool;
import com.shiguangji.entity.User;
import com.shiguangji.mapper.CategoryMapper;
import com.shiguangji.mapper.FavoriteMapper;
import com.shiguangji.mapper.IngredientMapper;
import com.shiguangji.mapper.RecipeImageMapper;
import com.shiguangji.mapper.RecipeMapper;
import com.shiguangji.mapper.RecipeStepMapper;
import com.shiguangji.mapper.RecipeToolMapper;
import com.shiguangji.mapper.ToolMapper;
import com.shiguangji.mapper.UserMapper;
import com.shiguangji.util.RedisCache;
import com.shiguangji.util.RedisKeys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

/**
 * 菜谱：首页瀑布流（5min 缓存）/ 热榜 zset / 详情（30min 缓存）/ 发布编辑删除（事务 + 缓存失效）
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RecipeService {

    private final RecipeMapper recipeMapper;
    private final RecipeImageMapper recipeImageMapper;
    private final IngredientMapper ingredientMapper;
    private final RecipeStepMapper recipeStepMapper;
    private final RecipeToolMapper recipeToolMapper;
    private final ToolMapper toolMapper;
    private final CategoryMapper categoryMapper;
    private final UserMapper userMapper;
    private final FavoriteMapper favoriteMapper;
    private final StringRedisTemplate redis;
    private final RedisCache redisCache;
    private final ObjectMapper objectMapper;

    // ---------------- 查询 ----------------

    /** 首页/分类瀑布流：cache-aside，5min */
    public List<RecipeCardVO> home(Long categoryId, int page, int size) {
        int p = Math.max(page, 1);
        int s = size <= 0 ? 6 : Math.min(size, 50);
        String key = RedisKeys.RECIPE_HOME + (categoryId == null ? 0 : categoryId) + ":" + p;
        List<RecipeCardVO> cached = redisCache.getList(key, RecipeCardVO.class);
        if (cached != null) {
            return cached;
        }
        List<RecipeCardVO> list = recipeMapper.selectHomeCards(categoryId, (p - 1) * s, s);
        fillImgRatio(list);
        redisCache.set(key, list, Duration.ofMinutes(5));
        return list;
    }

    /** 热门菜谱（zset，懒加载重建 + 每日 4 点定时刷新） */
    public List<RecipeCardVO> hot(int limit) {
        int l = limit <= 0 ? 10 : Math.min(limit, 50);
        Long size = redis.opsForZSet().size(RedisKeys.RECIPE_HOT);
        if (size == null || size == 0) {
            rebuildHot();
        }
        Set<String> members = redis.opsForZSet().reverseRange(RedisKeys.RECIPE_HOT, 0, l - 1L);
        if (members == null || members.isEmpty()) {
            return List.of();
        }
        List<RecipeCardVO> result = new ArrayList<>();
        for (String json : members) {
            RecipeCardVO vo = fromJsonQuiet(json);
            if (vo != null) {
                result.add(vo);
            }
        }
        return result;
    }

    /** 从 DB top100 重建热榜 zset（score = 收藏*2 + 浏览） */
    public void rebuildHot() {
        try {
            redis.delete(RedisKeys.RECIPE_HOT);
            List<RecipeCardVO> top = recipeMapper.selectHotCards(100);
            fillImgRatio(top);
            for (RecipeCardVO vo : top) {
                double score = vo.getFavoriteCount() == null ? 0 : vo.getFavoriteCount() * 2L;
                redis.opsForZSet().add(RedisKeys.RECIPE_HOT,
                        objectMapper.writeValueAsString(vo), score);
            }
        } catch (Exception e) {
            log.warn("rebuildHot failed", e);
        }
    }

    /** 菜谱详情：30min 缓存（收藏状态按用户实时计算），浏览计数 Redis+1 */
    public RecipeDetailVO detail(long id, Long currentUserId) {
        RecipeDetailVO vo = redisCache.get(RedisKeys.RECIPE_DETAIL + id, RecipeDetailVO.class);
        if (vo == null) {
            vo = buildDetail(id);
            if (vo != null) {
                redisCache.set(RedisKeys.RECIPE_DETAIL + id, vo, Duration.ofMinutes(30));
            }
        }
        if (vo == null) {
            throw new BizException(ErrorCode.RECIPE_NOT_FOUND);
        }
        // 浏览计数（Redis 累加，定时任务回写）
        redis.opsForValue().increment(RedisKeys.COUNTER_VIEW + id);
        redis.opsForSet().add(RedisKeys.COUNTER_PENDING, String.valueOf(id));
        // 实时计数：DB 基数 + Redis 待回写增量（让用户立即看到最新浏览/收藏数）
        String viewDeltaStr = redis.opsForValue().get(RedisKeys.COUNTER_VIEW + id);
        if (viewDeltaStr != null && vo.getViewCount() != null) {
            vo.setViewCount(vo.getViewCount() + Integer.parseInt(viewDeltaStr));
        }
        String favDeltaStr = redis.opsForValue().get(RedisKeys.COUNTER_FAVORITE + id);
        if (favDeltaStr != null && vo.getFavoriteCount() != null) {
            vo.setFavoriteCount(vo.getFavoriteCount() + Integer.parseInt(favDeltaStr));
        }
        // 收藏状态按当前用户计算（缓存内恒为 false，出缓存后覆写）
        vo.setFavorite(false);
        if (currentUserId != null) {
            Long cnt = favoriteMapper.selectCount(new LambdaQueryWrapper<Favorite>()
                    .eq(Favorite::getUserId, currentUserId)
                    .eq(Favorite::getRecipeId, id));
            vo.setFavorite(cnt != null && cnt > 0);
        }
        return vo;
    }

    /** 个人菜谱（按时间倒序，含草稿） */
    public List<RecipeCardVO> userRecipes(long userId, int page, int size) {
        int p = Math.max(page, 1);
        int s = size <= 0 ? 10 : Math.min(size, 50);
        List<RecipeCardVO> list = recipeMapper.selectUserCards(userId, (p - 1) * s, s);
        fillImgRatio(list);
        return list;
    }

    /** 按 ID 列表取瀑布流卡片（家庭菜谱用），保持传入顺序 */
    public List<RecipeCardVO> cardsByIds(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return List.of();
        }
        List<RecipeCardVO> cards = recipeMapper.selectCardsByIds(ids);
        fillImgRatio(cards);
        java.util.Map<Long, RecipeCardVO> byId = new java.util.HashMap<>();
        for (RecipeCardVO card : cards) {
            byId.put(card.getId(), card);
        }
        List<RecipeCardVO> ordered = new ArrayList<>();
        for (Long id : ids) {
            RecipeCardVO card = byId.get(id);
            if (card != null) {
                ordered.add(card);
            }
        }
        return ordered;
    }

    // ---------------- 写操作 ----------------

    @Transactional
    public Long publish(long userId, RecipePublishRequest req) {
        Long catExists = categoryMapper.selectCount(
                new LambdaQueryWrapper<Category>().eq(Category::getId, req.getCategoryId()));
        if (catExists == null || catExists == 0) {
            throw new BizException(ErrorCode.PARAM_INVALID, "分类不存在");
        }
        Recipe recipe = new Recipe();
        applyRequest(recipe, userId, req);
        recipe.setViewCount(0);
        recipe.setFavoriteCount(0);
        recipe.setStatus(1);
        recipeMapper.insert(recipe);
        saveChildren(recipe.getId(), req);
        evictListCaches();
        return recipe.getId();
    }

    @Transactional
    public void update(long userId, long id, RecipePublishRequest req) {
        Recipe recipe = requireOwnedRecipe(userId, id);
        applyRequest(recipe, userId, req);
        recipeMapper.updateById(recipe);
        // 子表全量重建
        recipeImageMapper.delete(new LambdaQueryWrapper<RecipeImage>()
                .eq(RecipeImage::getRecipeId, id));
        ingredientMapper.delete(new LambdaQueryWrapper<Ingredient>()
                .eq(Ingredient::getRecipeId, id));
        recipeStepMapper.delete(new LambdaQueryWrapper<RecipeStep>()
                .eq(RecipeStep::getRecipeId, id));
        recipeToolMapper.delete(new LambdaQueryWrapper<RecipeTool>()
                .eq(RecipeTool::getRecipeId, id));
        saveChildren(id, req);
        redisCache.delete(RedisKeys.RECIPE_DETAIL + id);
        evictListCaches();
    }

    @Transactional
    public void remove(long userId, long id) {
        requireOwnedRecipe(userId, id);
        recipeMapper.deleteById(id);   // 逻辑删除
        redisCache.delete(RedisKeys.RECIPE_DETAIL + id);
        evictListCaches();
    }

    // ---------------- 私有 ----------------

    private Recipe requireOwnedRecipe(long userId, long id) {
        Recipe recipe = recipeMapper.selectById(id);
        if (recipe == null) {
            throw new BizException(ErrorCode.RECIPE_NOT_FOUND);
        }
        if (!recipe.getUserId().equals(userId)) {
            throw new BizException(ErrorCode.NOT_RECIPE_OWNER);
        }
        return recipe;
    }

    private void applyRequest(Recipe recipe, long userId, RecipePublishRequest req) {
        recipe.setUserId(userId);
        recipe.setCategoryId(req.getCategoryId());
        recipe.setTitle(req.getTitle());
        recipe.setDescription(req.getDescription());
        recipe.setCoverUrl(req.getCoverUrl());
        recipe.setServings(req.getServings() == null ? 2 : req.getServings());
        recipe.setCookMinutes(req.getCookMinutes() == null ? 30 : req.getCookMinutes());
        recipe.setDifficulty(req.getDifficulty() == null ? 2 : req.getDifficulty());
        recipe.setTips(req.getTips());
        recipe.setNotes(req.getNotes());
        if (req.getExperience() != null) {
            recipe.setExpText(req.getExperience().getText());
            recipe.setExpHappenedAt(req.getExperience().getHappenedAt());
        } else {
            recipe.setExpText(null);
            recipe.setExpHappenedAt(null);
        }
    }

    private void saveChildren(long recipeId, RecipePublishRequest req) {
        // 图集
        if (req.getImages() != null) {
            int sort = 0;
            for (String url : req.getImages()) {
                if (url == null || url.isBlank()) {
                    continue;
                }
                RecipeImage img = new RecipeImage();
                img.setRecipeId(recipeId);
                img.setUrl(url);
                img.setSort(sort++);
                recipeImageMapper.insert(img);
            }
        }
        // 食材
        if (req.getIngredients() != null) {
            for (RecipePublishRequest.IngredientItem item : req.getIngredients()) {
                Ingredient ing = new Ingredient();
                ing.setRecipeId(recipeId);
                ing.setType(item.getType());
                ing.setName(item.getName());
                ing.setAmount(item.getAmount());
                ingredientMapper.insert(ing);
            }
        }
        // 步骤
        if (req.getSteps() != null) {
            int no = 1;
            for (String content : req.getSteps()) {
                if (content == null || content.isBlank()) {
                    continue;
                }
                RecipeStep step = new RecipeStep();
                step.setRecipeId(recipeId);
                step.setStepNo(no++);
                step.setContent(content);
                recipeStepMapper.insert(step);
            }
        }
        // 工具（过滤不存在的 id）
        if (req.getToolIds() != null && !req.getToolIds().isEmpty()) {
            List<Long> validIds = toolMapper.selectBatchIds(req.getToolIds())
                    .stream().map(Tool::getId).toList();
            for (Long toolId : validIds) {
                RecipeTool rt = new RecipeTool();
                rt.setRecipeId(recipeId);
                rt.setToolId(toolId);
                recipeToolMapper.insert(rt);
            }
        }
    }

    private RecipeDetailVO buildDetail(long id) {
        Recipe recipe = recipeMapper.selectById(id);
        if (recipe == null) {
            return null;
        }
        User author = userMapper.selectById(recipe.getUserId());
        Category category = categoryMapper.selectById(recipe.getCategoryId());
        List<RecipeImage> images = recipeImageMapper.selectList(
                new LambdaQueryWrapper<RecipeImage>()
                        .eq(RecipeImage::getRecipeId, id)
                        .orderByAsc(RecipeImage::getSort));
        List<Ingredient> ingredients = ingredientMapper.selectList(
                new LambdaQueryWrapper<Ingredient>()
                        .eq(Ingredient::getRecipeId, id)
                        .orderByAsc(Ingredient::getId));
        List<RecipeStep> steps = recipeStepMapper.selectList(
                new LambdaQueryWrapper<RecipeStep>()
                        .eq(RecipeStep::getRecipeId, id)
                        .orderByAsc(RecipeStep::getStepNo));
        List<RecipeTool> rts = recipeToolMapper.selectList(
                new LambdaQueryWrapper<RecipeTool>()
                        .eq(RecipeTool::getRecipeId, id));
        List<String> toolNames = List.of();
        if (!rts.isEmpty()) {
            List<Long> toolIds = rts.stream().map(RecipeTool::getToolId).toList();
            toolNames = toolMapper.selectBatchIds(toolIds).stream()
                    .map(Tool::getName).toList();
        }

        RecipeDetailVO vo = new RecipeDetailVO();
        vo.setId(recipe.getId());
        vo.setTitle(recipe.getTitle());
        vo.setAuthorName(author == null ? "未知用户" : author.getNickname());
        vo.setAuthorAvatar(author == null ? null : author.getAvatarUrl());
        vo.setFavoriteCount(recipe.getFavoriteCount());
        vo.setViewCount(recipe.getViewCount());
        vo.setCookMinutes(recipe.getCookMinutes());
        vo.setDifficulty(difficultyText(recipe.getDifficulty()));
        vo.setServings((recipe.getServings() == null ? 2 : recipe.getServings()) + " 人份");
        vo.setCategoryName(category == null ? null : category.getName());
        vo.setDescription(recipe.getDescription());
        vo.setImages(images.stream().map(RecipeImage::getUrl).toList());
        vo.setIngredients(ingredients.stream().map(i -> {
            RecipeDetailVO.IngredientVO item = new RecipeDetailVO.IngredientVO();
            item.setType(i.getType() != null && i.getType() == 2 ? "配料" : "主料");
            item.setName(i.getName());
            item.setAmount(i.getAmount());
            return item;
        }).toList());
        vo.setTools(toolNames);
        vo.setSteps(steps.stream().map(RecipeStep::getContent).toList());
        vo.setTips(recipe.getTips());
        vo.setNotes(recipe.getNotes() == null || recipe.getNotes().isBlank()
                ? List.of()
                : Arrays.stream(recipe.getNotes().split("\n"))
                        .map(String::trim).filter(x -> !x.isEmpty()).toList());
        if (recipe.getExpText() != null && !recipe.getExpText().isBlank()) {
            RecipeDetailVO.ExperienceVO exp = new RecipeDetailVO.ExperienceVO();
            exp.setText(recipe.getExpText());
            exp.setHappenedAt(recipe.getExpHappenedAt());
            exp.setCount(1);
            vo.setExperience(exp);
        }
        return vo;
    }

    private String difficultyText(Integer difficulty) {
        if (difficulty == null) {
            return "中等";
        }
        return switch (difficulty) {
            case 1 -> "简单";
            case 3 -> "困难";
            default -> "中等";
        };
    }

    /** 列表类缓存全失效（首页分页 + 热榜懒重建） */
    private void evictListCaches() {
        redisCache.deleteByPattern(RedisKeys.RECIPE_HOME + "*");
        redis.delete(RedisKeys.RECIPE_HOT);
    }

    private void fillImgRatio(List<RecipeCardVO> list) {
        if (list == null) {
            return;
        }
        for (RecipeCardVO vo : list) {
            long id = vo.getId() == null ? 0 : vo.getId();
            vo.setImgRatio(0.75 + Math.floorMod(id, 20) * 0.025);
        }
    }

    private RecipeCardVO fromJsonQuiet(String json) {
        try {
            return objectMapper.readValue(json, RecipeCardVO.class);
        } catch (Exception e) {
            return null;
        }
    }
}
