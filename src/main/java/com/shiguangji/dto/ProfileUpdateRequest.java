package com.shiguangji.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ProfileUpdateRequest {

    @Size(min = 1, max = 32, message = "昵称长度 1-32 字")
    private String nickname;

    @Size(max = 20, message = "手机号格式不正确")
    private String phone;

    @Size(max = 255, message = "头像 URL 过长")
    private String avatarUrl;
}
