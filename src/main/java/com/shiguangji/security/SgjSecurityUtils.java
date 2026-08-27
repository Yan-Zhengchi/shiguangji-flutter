package com.shiguangji.security;

import com.shiguangji.common.BizException;
import com.shiguangji.common.ErrorCode;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class SgjSecurityUtils {

    private SgjSecurityUtils() {
    }

    /** 当前登录用户 ID，未登录返回 null（匿名浏览接口用） */
    public static Long currentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof Long userId) {
            return userId;
        }
        return null;
    }

    /** 必须已登录，否则抛 40100 */
    public static Long requireUserId() {
        Long userId = currentUserId();
        if (userId == null) {
            throw new BizException(ErrorCode.UNAUTHORIZED);
        }
        return userId;
    }
}
