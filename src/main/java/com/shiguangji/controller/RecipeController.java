package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.dto.RecipeDetailVO;
import com.shiguangji.dto.RecipePublishRequest;
import com.shiguangji.security.SgjSecurityUtils;
import com.shiguangji.service.RecipeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/recipes")
@RequiredArgsConstructor
public class RecipeController {

    private final RecipeService recipeService;

    /** 首页/分类瀑布流（匿名可看，size 默认 6） */
    @GetMapping("/home")
    public Result<List<RecipeCardVO>> home(@RequestParam(required = false) Long categoryId,
                                           @RequestParam(defaultValue = "1") int page,
                                           @RequestParam(defaultValue = "6") int size) {
        return Result.ok(recipeService.home(categoryId, page, size));
    }

    /** 热门菜谱 */
    @GetMapping("/hot")
    public Result<List<RecipeCardVO>> hot(@RequestParam(defaultValue = "10") int limit) {
        return Result.ok(recipeService.hot(limit));
    }

    /** 详情（匿名可看；登录用户附带收藏状态） */
    @GetMapping("/{id}")
    public Result<RecipeDetailVO> detail(@PathVariable long id) {
        return Result.ok(recipeService.detail(id, SgjSecurityUtils.currentUserId()));
    }

    /** 发布菜谱 */
    @PostMapping
    public Result<Long> publish(@Valid @RequestBody RecipePublishRequest req) {
        return Result.ok(recipeService.publish(SgjSecurityUtils.requireUserId(), req));
    }

    /** 编辑（仅作者） */
    @PutMapping("/{id}")
    public Result<Void> update(@PathVariable long id,
                               @Valid @RequestBody RecipePublishRequest req) {
        recipeService.update(SgjSecurityUtils.requireUserId(), id, req);
        return Result.ok();
    }

    /** 删除（逻辑删除，仅作者） */
    @DeleteMapping("/{id}")
    public Result<Void> remove(@PathVariable long id) {
        recipeService.remove(SgjSecurityUtils.requireUserId(), id);
        return Result.ok();
    }
}
