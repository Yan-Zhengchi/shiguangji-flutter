package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("favorite")
public class Favorite {

    private Long userId;
    private Long recipeId;
    private LocalDateTime createdAt;
}
