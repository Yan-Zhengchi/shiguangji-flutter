package com.shiguangji.service;

import com.shiguangji.dto.CounterFlushItem;
import com.shiguangji.mapper.RecipeMapper;
import com.shiguangji.util.RedisKeys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * 定时任务：
 * 1. 每小时把 Redis 计数器（收藏/浏览）批量回写 MySQL
 * 2. 每日凌晨 4 点重建热榜 zset
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class CounterService {

    private final StringRedisTemplate redis;
    private final RecipeMapper recipeMapper;
    private final RecipeService recipeService;

    /** 每 10 分钟回写一次（比文档的 1h 更及时，量小无压力） */
    @Scheduled(fixedDelay = 600_000, initialDelay = 300_000)
    public void flushCounters() {
        Set<String> pending = redis.opsForSet().members(RedisKeys.COUNTER_PENDING);
        if (pending == null || pending.isEmpty()) {
            return;
        }
        List<CounterFlushItem> items = new ArrayList<>();
        for (String idStr : pending) {
            try {
                long recipeId = Long.parseLong(idStr);
                // StringRedisTemplate 的 getAndDelete 返回 String，需手动解析
                String favStr = redis.opsForValue().getAndDelete(RedisKeys.COUNTER_FAVORITE + recipeId);
                String viewStr = redis.opsForValue().getAndDelete(RedisKeys.COUNTER_VIEW + recipeId);
                redis.opsForSet().remove(RedisKeys.COUNTER_PENDING, idStr);
                int fav = favStr == null ? 0 : Integer.parseInt(favStr);
                int view = viewStr == null ? 0 : Integer.parseInt(viewStr);
                if (fav != 0 || view != 0) {
                    items.add(new CounterFlushItem(recipeId, fav, view));
                }
            } catch (NumberFormatException ignored) {
                redis.opsForSet().remove(RedisKeys.COUNTER_PENDING, idStr);
            }
        }
        if (!items.isEmpty()) {
            try {
                recipeMapper.batchFlushCounters(items);
                log.info("flushed {} recipe counters", items.size());
            } catch (Exception e) {
                log.warn("flush counters failed", e);
            }
        }
    }

    /** 每日 04:00 重建热榜 */
    @Scheduled(cron = "0 0 4 * * ?")
    public void refreshHot() {
        recipeService.rebuildHot();
    }
}
