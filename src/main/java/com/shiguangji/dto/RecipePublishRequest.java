package com.shiguangji.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.time.LocalDate;
import java.util.List;

/** 发布/编辑菜谱请求体（对应设计稿"新增菜谱页"12 张表单卡） */
@Data
public class RecipePublishRequest {

    @NotBlank(message = "标题不能为空")
    @Size(max = 64, message = "标题最长 64 字")
    private String title;

    @NotNull(message = "分类不能为空")
    private Long categoryId;

    @Size(max = 255, message = "封面 URL 过长")
    private String coverUrl;

    private List<String> images;

    @Size(max = 1000, message = "简介最长 1000 字")
    private String description;

    @Min(1) @Max(20)
    private Integer servings;

    @Min(1) @Max(1440)
    private Integer cookMinutes;

    /** 1 简单 2 中等 3 困难 */
    @Min(1) @Max(3)
    private Integer difficulty;

    @Valid
    private List<IngredientItem> ingredients;

    private List<Long> toolIds;

    @NotEmpty(message = "至少填写一个步骤")
    private List<String> steps;

    @Size(max = 1000, message = "妙招最长 1000 字")
    private String tips;

    /** 注意事项，多个用 \n 分隔 */
    @Size(max = 1000, message = "注意事项最长 1000 字")
    private String notes;

    @Valid
    private Experience experience;

    @Data
    public static class IngredientItem {
        /** 1 主料 2 配料 */
        @NotNull(message = "食材类型不能为空")
        @Min(1) @Max(2)
        private Integer type;
        @NotBlank(message = "食材名不能为空")
        @Size(max = 64)
        private String name;
        @Size(max = 32)
        private String amount;
    }

    /** 吃一堑长一智 */
    @Data
    public static class Experience {
        @Size(max = 1000, message = "经验最长 1000 字")
        private String text;
        private LocalDate happenedAt;
    }
}
