package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("recipe")
public class Recipe {

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private Long userId;
    private Long categoryId;
    private String title;
    private String description;
    private String coverUrl;
    private Integer servings;
    private Integer cookMinutes;
    /** 1 简单 2 中等 3 困难 */
    private Integer difficulty;
    private String tips;
    /** 注意事项，\n 分隔 */
    private String notes;
    private String expText;
    private LocalDate expHappenedAt;
    private Integer viewCount;
    private Integer favoriteCount;
    /** 1 上架 0 草稿 */
    private Integer status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    @TableLogic
    private Integer deleted;
}
