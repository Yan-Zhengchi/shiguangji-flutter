package com.shiguangji.util;

/**
 * Redis Key 规划（与架构设计文档 §6.1 一致）
 */
public final class RedisKeys {

    private RedisKeys() {
    }

    public static final String TOKEN_BLACKLIST = "token:blacklist:";
    public static final String REFRESH_TOKEN = "refresh:";
    public static final String RECIPE_DETAIL = "recipe:detail:";
    public static final String RECIPE_HOME = "recipe:home:";
    public static final String RECIPE_HOT = "recipe:hot";
    public static final String CATEGORIES = "recipe:categories";
    public static final String SEARCH_HISTORY = "search:history:";
    public static final String SEARCH_HOT = "search:hot";
    public static final String COUNTER_FAVORITE = "counter:favorite:";
    public static final String COUNTER_VIEW = "counter:view:";
    /** 待回写计数器的菜谱 ID 集合 */
    public static final String COUNTER_PENDING = "counter:pending";

    public static String refresh(long userId, String deviceId) {
        return REFRESH_TOKEN + userId + ":" + JwtDevice.of(deviceId);
    }

    /** 设备标识归一化（静态内部类避免与 security 包循环依赖） */
    public static final class JwtDevice {
        private JwtDevice() {
        }

        public static String of(String deviceId) {
            return (deviceId == null || deviceId.isBlank()) ? "default" : deviceId;
        }
    }
}
