package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("family_recipe")
public class FamilyRecipe {

    private Long familyId;
    private Long recipeId;
    private LocalDateTime createdAt;
}
