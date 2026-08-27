package com.shiguangji.dto;

import lombok.Data;

/** 瀑布流卡片（首页/分类/搜索/收藏/热榜通用） */
@Data
public class RecipeCardVO {

    private Long id;
    private String title;
    private String coverUrl;
    private String authorName;
    private Integer favoriteCount;
    /** 前端瀑布流高宽比（DB 未存尺寸，按 ID 生成确定性值） */
    private Double imgRatio;
}
