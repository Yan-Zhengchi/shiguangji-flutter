package com.shiguangji.dto;

import lombok.Data;

@Data
public class LogoutRequest {

    /** 可选：传入则同时吊销 refreshToken */
    private String refreshToken;
}
