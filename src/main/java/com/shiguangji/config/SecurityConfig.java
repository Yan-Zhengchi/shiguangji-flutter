package com.shiguangji.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.shiguangji.common.ErrorCode;
import com.shiguangji.common.Result;
import com.shiguangji.security.JwtAuthenticationFilter;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.nio.charset.StandardCharsets;
import java.util.List;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final ObjectMapper objectMapper;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // 匿名：注册/登录/刷新
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/register",
                                "/api/v1/auth/login", "/api/v1/auth/refresh").permitAll()
                        // 匿名：浏览/搜索类 GET
                        .requestMatchers(HttpMethod.GET, "/api/v1/categories", "/api/v1/recipes/**",
                                "/api/v1/search", "/api/v1/search/hot").permitAll()
                        // 匿名：健康检查 / API 文档 / 上传的静态图片 / 错误页
                        .requestMatchers("/actuator/health", "/doc.html", "/webjars/**",
                                "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html",
                                "/uploads/**", "/favicon.ico", "/error").permitAll()
                        // 其余（发布/编辑/删除/收藏/个人/家庭/搜索历史等）需登录
                        .anyRequest().authenticated())
                .exceptionHandling(eh -> eh
                        .authenticationEntryPoint((req, resp, ex) ->
                                writeJson(resp, 401, ErrorCode.UNAUTHORIZED))
                        .accessDeniedHandler((req, resp, ex) ->
                                writeJson(resp, 403, ErrorCode.FORBIDDEN)))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        config.setAllowedHeaders(List.of("*"));
        config.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    private void writeJson(HttpServletResponse resp, int status, ErrorCode ec) {
        try {
            resp.setStatus(status);
            resp.setContentType(MediaType.APPLICATION_JSON_VALUE);
            resp.setCharacterEncoding(StandardCharsets.UTF_8.name());
            resp.getWriter().write(objectMapper.writeValueAsString(Result.fail(ec)));
        } catch (Exception ignored) {
        }
    }
}
