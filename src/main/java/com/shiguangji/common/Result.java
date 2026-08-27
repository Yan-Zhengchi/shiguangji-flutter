package com.shiguangji.common;

import lombok.Data;

@Data
public class Result<T> {

    private int code;       // 0 成功，非 0 见错误码表
    private String message;
    private T data;

    public static <T> Result<T> ok(T data) {
        Result<T> r = new Result<>();
        r.code = 0;
        r.message = "ok";
        r.data = data;
        return r;
    }

    public static <T> Result<T> ok() {
        return ok(null);
    }

    public static <T> Result<T> fail(ErrorCode ec) {
        Result<T> r = new Result<>();
        r.code = ec.getCode();
        r.message = ec.getMessage();
        return r;
    }

    public static <T> Result<T> fail(ErrorCode ec, String message) {
        Result<T> r = new Result<>();
        r.code = ec.getCode();
        r.message = message;
        return r;
    }
}
