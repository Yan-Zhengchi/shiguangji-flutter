package com.shiguangji.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class FamilyVO {

    private Long id;
    private String name;
    private String coverUrl;
    private Long ownerId;
    private Integer memberCount;
    private LocalDateTime createdAt;
}
