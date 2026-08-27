package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.security.SgjSecurityUtils;
import com.shiguangji.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/favorites")
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteService favoriteService;

    @PostMapping("/{recipeId}")
    public Result<Void> favorite(@PathVariable long recipeId) {
        favoriteService.favorite(SgjSecurityUtils.requireUserId(), recipeId);
        return Result.ok();
    }

    @DeleteMapping("/{recipeId}")
    public Result<Void> unfavorite(@PathVariable long recipeId) {
        favoriteService.unfavorite(SgjSecurityUtils.requireUserId(), recipeId);
        return Result.ok();
    }

    @GetMapping
    public Result<List<RecipeCardVO>> list(@RequestParam(defaultValue = "1") int page,
                                           @RequestParam(defaultValue = "10") int size) {
        return Result.ok(favoriteService.list(SgjSecurityUtils.requireUserId(), page, size));
    }
}
