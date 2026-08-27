package com.shiguangji.controller;

import com.shiguangji.common.Result;
import com.shiguangji.dto.LoginRequest;
import com.shiguangji.dto.LogoutRequest;
import com.shiguangji.dto.RefreshRequest;
import com.shiguangji.dto.RegisterRequest;
import com.shiguangji.dto.TokenVO;
import com.shiguangji.dto.UserVO;
import com.shiguangji.security.SgjSecurityUtils;
import com.shiguangji.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public Result<TokenVO> register(@Valid @RequestBody RegisterRequest req) {
        return Result.ok(authService.register(req));
    }

    @PostMapping("/login")
    public Result<TokenVO> login(@Valid @RequestBody LoginRequest req) {
        return Result.ok(authService.login(req));
    }

    @PostMapping("/refresh")
    public Result<TokenVO> refresh(@Valid @RequestBody RefreshRequest req) {
        return Result.ok(authService.refresh(req));
    }

    @PostMapping("/logout")
    public Result<Void> logout(HttpServletRequest request,
                                @RequestBody(required = false) LogoutRequest req) {
        authService.logout(request, req);
        return Result.ok();
    }

    @GetMapping("/me")
    public Result<UserVO> me() {
        return Result.ok(authService.me(SgjSecurityUtils.requireUserId()));
    }
}
