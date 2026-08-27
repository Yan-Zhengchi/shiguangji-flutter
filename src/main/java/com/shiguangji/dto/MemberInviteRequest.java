package com.shiguangji.dto;

import lombok.Data;

/** 邀请成员：按用户名或手机号（二选一） */
@Data
public class MemberInviteRequest {

    private String username;

    private String phone;
}
