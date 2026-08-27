package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.dto.ProfileUpdateRequest;
import com.shiguangji.dto.ProfileVO;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.security.SgjSecurityUtils;
import com.shiguangji.service.RecipeService;
import com.shiguangji.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final RecipeService recipeService;

    /** 个人页聚合：资料 + 统计 */
    @GetMapping("/profile")
    public Result<ProfileVO> profile() {
        return Result.ok(userService.profile(SgjSecurityUtils.requireUserId()));
    }

    @PutMapping("/profile")
    public Result<ProfileVO> update(@Valid @RequestBody ProfileUpdateRequest req) {
        return Result.ok(userService.update(SgjSecurityUtils.requireUserId(), req));
    }

    /** 个人菜谱（按时间倒序） */
    @GetMapping("/recipes")
    public Result<List<RecipeCardVO>> myRecipes(@RequestParam(defaultValue = "1") int page,
                                                @RequestParam(defaultValue = "10") int size) {
        return Result.ok(recipeService.userRecipes(SgjSecurityUtils.requireUserId(), page, size));
    }
}
