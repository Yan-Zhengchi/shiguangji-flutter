package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.service.UploadService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/uploads")
@RequiredArgsConstructor
public class UploadController {

    private final UploadService uploadService;

    /** 图片直传（multipart）。OSS 配置后可切换为直传签名模式 */
    @PostMapping("/image")
    public Result<String> upload(@RequestParam("file") MultipartFile file) {
        return Result.ok(uploadService.store(file));
    }
}
