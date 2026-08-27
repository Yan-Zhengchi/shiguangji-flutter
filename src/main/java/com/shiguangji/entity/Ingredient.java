package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("ingredient")
public class Ingredient {

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private Long recipeId;
    /** 1 主料 2 配料 */
    private Integer type;
    private String name;
    private String amount;
}
