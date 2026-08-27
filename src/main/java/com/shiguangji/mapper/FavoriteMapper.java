package com.shiguangji.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.shiguangji.dto.RecipeCardVO;
import com.shiguangji.entity.Favorite;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface FavoriteMapper extends BaseMapper<Favorite> {

    /** 我的收藏（按收藏时间倒序） */
    List<RecipeCardVO> selectFavoriteCards(@Param("userId") Long userId,
                                           @Param("offset") int offset, @Param("size") int size);
}
