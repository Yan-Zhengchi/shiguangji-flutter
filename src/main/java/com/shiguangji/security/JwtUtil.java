package com.shiguangji.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

/**
 * JWT 工具：AccessToken（2h，无状态）+ RefreshToken（30d，Redis 可吊销）
 */
@Component
public class JwtUtil {

    public static final String TYPE_ACCESS = "access";
    public static final String TYPE_REFRESH = "refresh";

    private final SecretKey key;
    private final JwtProperties props;

    public JwtUtil(JwtProperties props) {
        this.props = props;
        this.key = Keys.hmacShaKeyFor(props.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    public String createAccessToken(long userId) {
        long now = System.currentTimeMillis();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .id(UUID.randomUUID().toString())                 // jti：登出黑名单依据
                .claim("type", TYPE_ACCESS)
                .issuedAt(new Date(now))
                .expiration(new Date(now + props.getAccessTtl().toMillis()))
                .signWith(key)
                .compact();
    }

    public String createRefreshToken(long userId, String deviceId) {
        long now = System.currentTimeMillis();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .id(UUID.randomUUID().toString())
                .claim("type", TYPE_REFRESH)
                .claim("deviceId", normalizeDevice(deviceId))
                .issuedAt(new Date(now))
                .expiration(new Date(now + props.getRefreshTtl().toMillis()))
                .signWith(key)
                .compact();
    }

    /** 解析并校验签名与有效期，失败抛 JwtException */
    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }

    public long accessTtlMillis() {
        return props.getAccessTtl().toMillis();
    }

    public long refreshTtlMillis() {
        return props.getRefreshTtl().toMillis();
    }

    public static String normalizeDevice(String deviceId) {
        return (deviceId == null || deviceId.isBlank()) ? "default" : deviceId;
    }
}
