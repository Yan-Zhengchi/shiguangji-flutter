package com.shiguangji.dto;

import lombok.Data;

@Data
public class ProfileVO {

    private Long userId;
    private String username;
    private String nickname;
    private String phone;
    private String avatarUrl;
    private Stats stats;

    @Data
    public static class Stats {
        private Long recipeCount;
        private Long favoriteCount;
        private Long familyCount;
    }
}
