package com.shiguangji.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class FamilyCreateRequest {

    @NotBlank(message = "家庭名称不能为空")
    @Size(max = 64, message = "家庭名称最长 64 字")
    private String name;

    @Size(max = 255)
    private String coverUrl;
}
