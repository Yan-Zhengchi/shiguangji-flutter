package com.shiguangji.dto;

import lombok.Data;

@Data
public class TokenVO {

    private Long userId;
    private String username;
    private String nickname;
    private String avatarUrl;
    private String accessToken;
    private String refreshToken;
    /** accessToken 有效期（秒） */
    private Long expiresIn;
}
