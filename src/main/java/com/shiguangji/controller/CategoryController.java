package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.dto.CategoryVO;
import com.shiguangji.service.CategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @GetMapping("/categories")
    public Result<List<CategoryVO>> list() {
        return Result.ok(categoryService.list());
    }
}
