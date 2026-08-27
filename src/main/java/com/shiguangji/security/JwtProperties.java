package com.shiguangji.security;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Data
@Component
@ConfigurationProperties(prefix = "shiguangji.jwt")
public class JwtProperties {

    private String secret;
    private Duration accessTtl = Duration.ofHours(2);
    private Duration refreshTtl = Duration.ofDays(30);
}
