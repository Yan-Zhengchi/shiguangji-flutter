package com.shiguangji.dto;

import lombok.Data;

import java.time.LocalDate;
import java.util.List;

/** 菜谱详情（对应设计稿"菜谱详情页"卡片结构） */
@Data
public class RecipeDetailVO {

    private Long id;
    private String title;
    private String authorName;
    private String authorAvatar;
    private Integer favoriteCount;
    private Integer viewCount;
    private Integer cookMinutes;
    /** 简单/中等/困难 */
    private String difficulty;
    /** 如 "2 人份" */
    private String servings;
    private String categoryName;
    private String description;
    private List<IngredientVO> ingredients;
    private List<String> tools;
    private List<String> steps;
    private String tips;
    private List<String> notes;
    private ExperienceVO experience;
    /** 当前用户是否已收藏（匿名恒为 false） */
    private Boolean favorite;
    private List<String> images;

    @Data
    public static class IngredientVO {
        /** 主料/配料 */
        private String type;
        private String name;
        private String amount;
    }

    /** 吃一堑长一智 */
    @Data
    public static class ExperienceVO {
        private String text;
        private LocalDate happenedAt;
        private Integer count;
    }
}
