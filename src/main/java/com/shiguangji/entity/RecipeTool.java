package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("recipe_tool")
public class RecipeTool {

    private Long recipeId;
    private Long toolId;
}
