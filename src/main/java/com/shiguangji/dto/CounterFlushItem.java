package com.shiguangji.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/** Redis 计数器回写 MySQL 的载体 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CounterFlushItem {

    private Long recipeId;
    private int favoriteDelta;
    private int viewDelta;
}
