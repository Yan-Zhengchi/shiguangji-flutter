package com.shiguangji.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.shiguangji.entity.Recipe;
import com.shiguangji.dto.CounterFlushItem;
import com.shiguangji.dto.RecipeCardVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface RecipeMapper extends BaseMapper<Recipe> {

    /** 首页/分类瀑布流：(favorite*2 + view) 倒序 */
    List<RecipeCardVO> selectHomeCards(@Param("categoryId") Long categoryId,
                                       @Param("offset") int offset, @Param("size") int size);

    /** 热门榜（DB 侧取 top N 重建 zset） */
    List<RecipeCardVO> selectHotCards(@Param("limit") int limit);

    /** 个人菜谱（按时间倒序，含草稿） */
    List<RecipeCardVO> selectUserCards(@Param("userId") Long userId,
                                       @Param("offset") int offset, @Param("size") int size);

    /** FULLTEXT（ngram）搜索 */
    List<RecipeCardVO> searchByFulltext(@Param("keyword") String keyword,
                                        @Param("offset") int offset, @Param("size") int size);

    /** LIKE 兜底（关键词 1 字时 ngram 无法分词） */
    List<RecipeCardVO> searchByLike(@Param("keyword") String keyword,
                                    @Param("offset") int offset, @Param("size") int size);

    /** 计数器批量回写（Redis → MySQL） */
    int batchFlushCounters(@Param("items") List<CounterFlushItem> items);

    /** 按 ID 列表取瀑布流卡片（家庭菜谱用） */
    List<RecipeCardVO> selectCardsByIds(@Param("ids") List<Long> ids);
}
