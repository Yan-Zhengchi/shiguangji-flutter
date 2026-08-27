package com.shiguangji.service;

import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.entity.SearchHistory;
import com.shiguangji.mapper.RecipeMapper;
import com.shiguangji.mapper.SearchHistoryMapper;
import com.shiguangji.util.RedisKeys;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.List;
import java.util.Set;

/**
 * 搜索：FULLTEXT(ngram) / LIKE 兜底；历史与热搜落 Redis
 */
@Service
@RequiredArgsConstructor
public class SearchService {

    private final RecipeMapper recipeMapper;
    private final SearchHistoryMapper searchHistoryMapper;
    private final StringRedisTemplate redis;

    public List<RecipeCardVO> search(Long userId, String keyword, int page, int size) {
        int p = Math.max(page, 1);
        int s = size <= 0 ? 10 : Math.min(size, 50);
        String kw = keyword == null ? "" : keyword.trim();
        if (kw.isEmpty()) {
            return List.of();
        }
        recordHistory(userId, kw);
        bumpHotKeyword(kw);

        int offset = (p - 1) * s;
        List<RecipeCardVO> list;
        if (kw.length() >= 2) {
            // ngram 最小 token 为 2，≥2 字走全文索引
            list = recipeMapper.searchByFulltext(kw, offset, s);
        } else {
            list = recipeMapper.searchByLike(escapeLike(kw), offset, s);
        }
        fillImgRatio(list);
        return list;
    }

    /** 热搜词 Top10 */
    public List<String> hotKeywords() {
        Set<String> keywords = redis.opsForZSet().reverseRange(RedisKeys.SEARCH_HOT, 0, 9);
        if (keywords == null) {
            return List.of();
        }
        return List.copyOf(keywords);
    }

    /** 个人历史（去重最近 20 条） */
    public List<String> history(long userId) {
        List<String> list = redis.opsForList().range(RedisKeys.SEARCH_HISTORY + userId, 0, -1);
        return list == null ? List.of() : list;
    }

    public void clearHistory(long userId) {
        redis.delete(RedisKeys.SEARCH_HISTORY + userId);
    }

    private void recordHistory(Long userId, String keyword) {
        if (userId == null) {
            return;
        }
        String key = RedisKeys.SEARCH_HISTORY + userId;
        // 去重：先移除旧记录再插入头部，保留最近 20 条
        redis.opsForList().remove(key, 0, keyword);
        redis.opsForList().leftPush(key, keyword);
        redis.opsForList().trim(key, 0, 19);
        redis.expire(key, Duration.ofDays(90));
        // 审计落库（Redis 为查询源，表为存档）
        SearchHistory history = new SearchHistory();
        history.setUserId(userId);
        history.setKeyword(keyword);
        searchHistoryMapper.insert(history);
    }

    private void bumpHotKeyword(String keyword) {
        redis.opsForZSet().incrementScore(RedisKeys.SEARCH_HOT, keyword, 1);
        redis.expire(RedisKeys.SEARCH_HOT, Duration.ofHours(1));
    }

    private String escapeLike(String kw) {
        return kw.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
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
}
