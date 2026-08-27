package com.shiguangji.dto;

import lombok.Data;

@Data
public class UserVO {

    private Long userId;
    private String username;
    private String nickname;
    private String phone;
    private String avatarUrl;
}
