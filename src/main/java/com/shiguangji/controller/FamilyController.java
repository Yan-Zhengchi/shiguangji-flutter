package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.dto.FamilyCreateRequest;
import com.shiguangji.dto.FamilyVO;
import com.shiguangji.dto.MemberInviteRequest;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.security.SgjSecurityUtils;
import com.shiguangji.service.FamilyService;
import com.shiguangji.service.RecipeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/families")
@RequiredArgsConstructor
public class FamilyController {

    private final FamilyService familyService;
    private final RecipeService recipeService;

    @GetMapping
    public Result<List<FamilyVO>> list() {
        return Result.ok(familyService.list(SgjSecurityUtils.requireUserId()));
    }

    @PostMapping
    public Result<FamilyVO> create(@Valid @RequestBody FamilyCreateRequest req) {
        return Result.ok(familyService.create(SgjSecurityUtils.requireUserId(), req));
    }

    /** 邀请成员（按用户名/手机号） */
    @PostMapping("/{id}/members")
    public Result<Void> invite(@PathVariable long id, @RequestBody MemberInviteRequest req) {
        familyService.inviteMember(SgjSecurityUtils.requireUserId(), id, req);
        return Result.ok();
    }

    /** 家庭菜谱列表（成员可见，卡片结构） */
    @GetMapping("/{id}/recipes")
    public Result<List<RecipeCardVO>> recipes(@PathVariable long id) {
        List<Long> ids = familyService.familyRecipeIds(SgjSecurityUtils.requireUserId(), id);
        return Result.ok(recipeService.cardsByIds(ids));
    }

    @PostMapping("/{id}/recipes/{recipeId}")
    public Result<Void> addRecipe(@PathVariable long id, @PathVariable long recipeId) {
        familyService.addRecipe(SgjSecurityUtils.requireUserId(), id, recipeId);
        return Result.ok();
    }

    @DeleteMapping("/{id}/recipes/{recipeId}")
    public Result<Void> removeRecipe(@PathVariable long id, @PathVariable long recipeId) {
        familyService.removeRecipe(SgjSecurityUtils.requireUserId(), id, recipeId);
        return Result.ok();
    }
}
