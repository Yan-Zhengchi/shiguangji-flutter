package com.shiguangji.common;

import lombok.Getter;

/**
 * 错误码分域：0 成功 / 1xxx 通用 / 2xxx 用户 / 3xxx 菜谱 / 4xxx 家庭 / 5xxx 系统
 */
@Getter
public enum ErrorCode {

    OK(0, "成功", 200),
    PARAM_INVALID(40010, "参数校验失败", 400),
    UNAUTHORIZED(40100, "未登录或 Token 失效", 401),
    FORBIDDEN(40301, "无权限执行该操作", 403),
    NOT_FOUND(40400, "资源不存在", 404),

    USERNAME_OR_PASSWORD_ERROR(20001, "用户名或密码错误", 400),
    USERNAME_EXISTS(20002, "用户名已存在", 400),
    USER_NOT_FOUND(20003, "用户不存在", 400),

    RECIPE_NOT_FOUND(30001, "菜谱不存在", 404),
    NOT_RECIPE_OWNER(30002, "无权操作他人菜谱", 403),
    ALREADY_FAVORITED(30004, "已收藏该菜谱", 400),

    FAMILY_NOT_FOUND(40001, "家庭不存在或非成员", 404),
    ALREADY_FAMILY_MEMBER(40002, "该用户已是家庭成员", 400),

    SYSTEM_ERROR(50000, "系统内部错误", 500);

    private final int code;
    private final String message;
    private final int httpStatus;

    ErrorCode(int code, String message, int httpStatus) {
        this.code = code;
        this.message = message;
        this.httpStatus = httpStatus;
    }
}
