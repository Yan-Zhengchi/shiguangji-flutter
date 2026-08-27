package com.shiguangji.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("tool")
public class Tool {

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private Long id;
    private String name;
}
