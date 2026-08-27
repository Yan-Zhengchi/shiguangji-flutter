package com.shiguangji.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.shiguangji.entity.Ingredient;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface IngredientMapper extends BaseMapper<Ingredient> {
}
