package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("family_member")
public class FamilyMember {

    private Long familyId;
    private Long userId;
    /** OWNER / MEMBER */
    private String role;
}
