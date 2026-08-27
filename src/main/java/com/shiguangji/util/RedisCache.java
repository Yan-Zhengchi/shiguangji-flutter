package com.shiguangji.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.Cursor;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.ScanOptions;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Redis 缓存帮助类：JSON 序列化 + SCAN 模式删除
 */
@Component
@RequiredArgsConstructor
public class RedisCache {

    private final StringRedisTemplate redis;
    private final ObjectMapper objectMapper;

    public <T> T get(String key, Class<T> type) {
        String json = redis.opsForValue().get(key);
        if (json == null) {
            return null;
        }
        try {
            return objectMapper.readValue(json, type);
        } catch (Exception e) {
            return null;
        }
    }

    public <T> List<T> getList(String key, Class<T> type) {
        String json = redis.opsForValue().get(key);
        if (json == null) {
            return null;
        }
        try {
            return objectMapper.readValue(json, objectMapper.getTypeFactory()
                    .constructCollectionType(List.class, type));
        } catch (Exception e) {
            return null;
        }
    }

    public void set(String key, Object value, Duration ttl) {
        try {
            String json = objectMapper.writeValueAsString(value);
            if (ttl == null) {
                redis.opsForValue().set(key, json);
            } else {
                redis.opsForValue().set(key, json, ttl);
            }
        } catch (Exception ignored) {
        }
    }

    public void delete(String key) {
        redis.delete(key);
    }

    /** 按模式批量删除（SCAN，禁止 KEYS） */
    public void deleteByPattern(String pattern) {
        Set<String> keys = redis.execute((RedisCallback<Set<String>>) connection -> {
            Set<String> result = new HashSet<>();
            try (Cursor<byte[]> cursor = connection.keyCommands()
                    .scan(ScanOptions.scanOptions().match(pattern).count(1000).build())) {
                cursor.forEachRemaining(bytes -> result.add(new String(bytes, StandardCharsets.UTF_8)));
            }
            return result;
        });
        if (keys != null && !keys.isEmpty()) {
            redis.delete(keys);
        }
    }
}
