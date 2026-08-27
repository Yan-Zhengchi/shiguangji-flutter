package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("recipe_step")
public class RecipeStep {

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private Long recipeId;
    private Integer stepNo;
    private String content;
}
