package com.shiguangji.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shiguangji.common.BizException;
import com.shiguangji.common.ErrorCode;
import com.shiguangji.dto.LoginRequest;
import com.shiguangji.dto.LogoutRequest;
import com.shiguangji.dto.RefreshRequest;
import com.shiguangji.dto.RegisterRequest;
import com.shiguangji.dto.TokenVO;
import com.shiguangji.dto.UserVO;
import com.shiguangji.entity.User;
import com.shiguangji.mapper.UserMapper;
import com.shiguangji.security.JwtUtil;
import com.shiguangji.util.RedisKeys;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;

/**
 * 认证：注册/登录/双 Token 续期/登出（黑名单）
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final StringRedisTemplate redis;

    @Transactional
    public TokenVO register(RegisterRequest req) {
        Long exists = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getUsername, req.getUsername()));
        if (exists != null && exists > 0) {
            throw new BizException(ErrorCode.USERNAME_EXISTS);
        }
        User user = new User();
        user.setUsername(req.getUsername());
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setNickname(req.getNickname());
        user.setPhone(req.getPhone());
        userMapper.insert(user);
        return issueTokens(user, "default");
    }

    public TokenVO login(LoginRequest req) {
        User user = userMapper.selectOne(
                new LambdaQueryWrapper<User>().eq(User::getUsername, req.getUsername()));
        if (user == null || !passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new BizException(ErrorCode.USERNAME_OR_PASSWORD_ERROR);
        }
        return issueTokens(user, req.getDeviceId());
    }

    /** 用 refreshToken 换新双 Token（旋转式：旧 refresh 立即失效） */
    public TokenVO refresh(RefreshRequest req) {
        Claims claims;
        try {
            claims = jwtUtil.parse(req.getRefreshToken());
        } catch (JwtException | IllegalArgumentException e) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        if (!JwtUtil.TYPE_REFRESH.equals(claims.get("type", String.class))) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        long userId;
        try {
            userId = Long.parseLong(claims.getSubject());
        } catch (NumberFormatException e) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        String deviceId = claims.get("deviceId", String.class);
        String stored = redis.opsForValue().get(RedisKeys.refresh(userId, deviceId));
        if (stored == null || !stored.equals(req.getRefreshToken())) {
            // 已被旋转/登出/踢出
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        return issueTokens(user, deviceId);
    }

    /** 登出：accessToken jti 进黑名单（剩余有效期），refreshToken 主动吊销 */
    public void logout(HttpServletRequest request, LogoutRequest req) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7).trim();
            try {
                Claims claims = jwtUtil.parse(token);
                long remaining = claims.getExpiration().getTime() - System.currentTimeMillis();
                if (remaining > 0) {
                    redis.opsForValue().set(RedisKeys.TOKEN_BLACKLIST + claims.getId(), "1",
                            Duration.ofMillis(remaining));
                }
            } catch (JwtException | IllegalArgumentException ignored) {
            }
        }
        if (req != null && req.getRefreshToken() != null && !req.getRefreshToken().isBlank()) {
            try {
                Claims claims = jwtUtil.parse(req.getRefreshToken());
                long userId = Long.parseLong(claims.getSubject());
                String deviceId = claims.get("deviceId", String.class);
                redis.delete(RedisKeys.refresh(userId, deviceId));
            } catch (JwtException | IllegalArgumentException ignored) {
            }
        }
    }

    public UserVO me(long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        return toUserVO(user);
    }

    private TokenVO issueTokens(User user, String deviceId) {
        String device = JwtUtil.normalizeDevice(deviceId);
        String accessToken = jwtUtil.createAccessToken(user.getId());
        String refreshToken = jwtUtil.createRefreshToken(user.getId(), device);
        redis.opsForValue().set(RedisKeys.refresh(user.getId(), device), refreshToken,
                Duration.ofMillis(jwtUtil.refreshTtlMillis()));

        TokenVO vo = new TokenVO();
        vo.setUserId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setNickname(user.getNickname());
        vo.setAvatarUrl(user.getAvatarUrl());
        vo.setAccessToken(accessToken);
        vo.setRefreshToken(refreshToken);
        vo.setExpiresIn(jwtUtil.accessTtlMillis() / 1000);
        return vo;
    }

    private UserVO toUserVO(User user) {
        UserVO vo = new UserVO();
        vo.setUserId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setNickname(user.getNickname());
        vo.setPhone(user.getPhone());
        vo.setAvatarUrl(user.getAvatarUrl());
        return vo;
    }
}
