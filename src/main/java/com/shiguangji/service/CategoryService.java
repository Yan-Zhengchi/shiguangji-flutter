package com.shiguangji.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shiguangji.dto.CategoryVO;
import com.shiguangji.entity.Category;
import com.shiguangji.mapper.CategoryMapper;
import com.shiguangji.util.RedisCache;
import com.shiguangji.util.RedisKeys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 分类（Redis 缓存，静态数据无 TTL）
 */
@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryMapper categoryMapper;
    private final RedisCache redisCache;

    public List<CategoryVO> list() {
        List<CategoryVO> cached = redisCache.getList(RedisKeys.CATEGORIES, CategoryVO.class);
        if (cached != null) {
            return cached;
        }
        List<Category> categories = categoryMapper.selectList(
                new LambdaQueryWrapper<Category>().orderByAsc(Category::getSort));
        List<CategoryVO> vos = categories.stream().map(c -> {
            CategoryVO vo = new CategoryVO();
            vo.setId(c.getId());
            vo.setName(c.getName());
            vo.setIcon(c.getIcon());
            vo.setSort(c.getSort());
            return vo;
        }).toList();
        if (!vos.isEmpty()) {
            redisCache.set(RedisKeys.CATEGORIES, vos, null);
        }
        return vos;
    }
}
