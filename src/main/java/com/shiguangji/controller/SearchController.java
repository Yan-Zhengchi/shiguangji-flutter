package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.security.SgjSecurityUtils;
import com.shiguangji.service.RecipeService;
import com.shiguangji.service.SearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class SearchController {

    private final SearchService searchService;
    private final RecipeService recipeService;

    /** 关键词搜索（匿名可搜；登录用户计入历史与热搜） */
    @GetMapping("/search")
    public Result<List<RecipeCardVO>> search(@RequestParam String keyword,
                                             @RequestParam(defaultValue = "1") int page,
                                             @RequestParam(defaultValue = "10") int size) {
        return Result.ok(searchService.search(SgjSecurityUtils.currentUserId(), keyword, page, size));
    }

    /** 热搜词 Top10 */
    @GetMapping("/search/hot")
    public Result<List<String>> hot() {
        return Result.ok(searchService.hotKeywords());
    }

    /** 个人搜索历史（登录） */
    @GetMapping("/search/history")
    public Result<List<String>> history() {
        return Result.ok(searchService.history(SgjSecurityUtils.requireUserId()));
    }

    /** 清空历史 */
    @DeleteMapping("/search/history")
    public Result<Void> clearHistory() {
        searchService.clearHistory(SgjSecurityUtils.requireUserId());
        return Result.ok();
    }
}
