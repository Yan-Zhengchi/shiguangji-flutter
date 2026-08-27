package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("family")
public class Family {

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private String name;
    private Long ownerId;
    private String coverUrl;
    private LocalDateTime createdAt;
    @TableLogic
    private Integer deleted;
}
