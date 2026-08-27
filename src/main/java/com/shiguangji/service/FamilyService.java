package com.shiguangji.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.shiguangji.common.BizException;
import com.shiguangji.common.ErrorCode;
import com.shiguangji.dto.FamilyCreateRequest;
import com.shiguangji.dto.FamilyVO;
import com.shiguangji.dto.MemberInviteRequest;
import com.shiguangji.entity.Family;
import com.shiguangji.entity.FamilyMember;
import com.shiguangji.entity.FamilyRecipe;
import com.shiguangji.entity.User;
import com.shiguangji.mapper.FamilyMapper;
import com.shiguangji.mapper.FamilyMemberMapper;
import com.shiguangji.mapper.FamilyRecipeMapper;
import com.shiguangji.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 家庭：创建/邀请成员/家庭菜谱共享
 */
@Service
@RequiredArgsConstructor
public class FamilyService {

    private final FamilyMapper familyMapper;
    private final FamilyMemberMapper familyMemberMapper;
    private final FamilyRecipeMapper familyRecipeMapper;
    private final UserMapper userMapper;

    public List<FamilyVO> list(long userId) {
        List<FamilyMember> memberships = familyMemberMapper.selectList(
                new LambdaQueryWrapper<FamilyMember>().eq(FamilyMember::getUserId, userId));
        if (memberships.isEmpty()) {
            return List.of();
        }
        List<Long> familyIds = memberships.stream().map(FamilyMember::getFamilyId).toList();
        return familyMapper.selectBatchIds(familyIds).stream()
                .map(family -> toVO(family, countMembers(family.getId())))
                .toList();
    }

    @Transactional
    public FamilyVO create(long userId, FamilyCreateRequest req) {
        Family family = new Family();
        family.setName(req.getName());
        family.setOwnerId(userId);
        family.setCoverUrl(req.getCoverUrl());
        familyMapper.insert(family);

        FamilyMember member = new FamilyMember();
        member.setFamilyId(family.getId());
        member.setUserId(userId);
        member.setRole("OWNER");
        familyMemberMapper.insert(member);
        return toVO(family, 1);
    }

    @Transactional
    public void inviteMember(long inviterId, long familyId, MemberInviteRequest req) {
        requireMembership(inviterId, familyId);
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        if (req.getUsername() != null && !req.getUsername().isBlank()) {
            wrapper.eq(User::getUsername, req.getUsername().trim());
        } else if (req.getPhone() != null && !req.getPhone().isBlank()) {
            wrapper.eq(User::getPhone, req.getPhone().trim());
        } else {
            throw new BizException(ErrorCode.PARAM_INVALID, "用户名或手机号至少填一个");
        }
        User target = userMapper.selectOne(wrapper);
        if (target == null) {
            throw new BizException(ErrorCode.USER_NOT_FOUND);
        }
        Long exists = familyMemberMapper.selectCount(new LambdaQueryWrapper<FamilyMember>()
                .eq(FamilyMember::getFamilyId, familyId)
                .eq(FamilyMember::getUserId, target.getId()));
        if (exists != null && exists > 0) {
            throw new BizException(ErrorCode.ALREADY_FAMILY_MEMBER);
        }
        FamilyMember member = new FamilyMember();
        member.setFamilyId(familyId);
        member.setUserId(target.getId());
        member.setRole("MEMBER");
        try {
            familyMemberMapper.insert(member);
        } catch (DuplicateKeyException e) {
            throw new BizException(ErrorCode.ALREADY_FAMILY_MEMBER);
        }
    }

    @Transactional
    public void addRecipe(long userId, long familyId, long recipeId) {
        requireMembership(userId, familyId);
        Long exists = familyRecipeMapper.selectCount(new LambdaQueryWrapper<FamilyRecipe>()
                .eq(FamilyRecipe::getFamilyId, familyId)
                .eq(FamilyRecipe::getRecipeId, recipeId));
        if (exists != null && exists > 0) {
            return;   // 幂等
        }
        FamilyRecipe fr = new FamilyRecipe();
        fr.setFamilyId(familyId);
        fr.setRecipeId(recipeId);
        try {
            familyRecipeMapper.insert(fr);
        } catch (DuplicateKeyException ignored) {
        }
    }

    @Transactional
    public void removeRecipe(long userId, long familyId, long recipeId) {
        requireMembership(userId, familyId);
        familyRecipeMapper.delete(new LambdaQueryWrapper<FamilyRecipe>()
                .eq(FamilyRecipe::getFamilyId, familyId)
                .eq(FamilyRecipe::getRecipeId, recipeId));
    }

    public List<Long> familyRecipeIds(long userId, long familyId) {
        requireMembership(userId, familyId);
        return familyRecipeMapper.selectList(new LambdaQueryWrapper<FamilyRecipe>()
                        .eq(FamilyRecipe::getFamilyId, familyId)
                        .orderByDesc(FamilyRecipe::getCreatedAt))
                .stream().map(FamilyRecipe::getRecipeId).toList();
    }

    private void requireMembership(long userId, long familyId) {
        Family family = familyMapper.selectById(familyId);
        if (family == null) {
            throw new BizException(ErrorCode.FAMILY_NOT_FOUND);
        }
        Long cnt = familyMemberMapper.selectCount(new LambdaQueryWrapper<FamilyMember>()
                .eq(FamilyMember::getFamilyId, familyId)
                .eq(FamilyMember::getUserId, userId));
        if (cnt == null || cnt == 0) {
            throw new BizException(ErrorCode.FAMILY_NOT_FOUND);
        }
    }

    private long countMembers(long familyId) {
        Long cnt = familyMemberMapper.selectCount(new LambdaQueryWrapper<FamilyMember>()
                .eq(FamilyMember::getFamilyId, familyId));
        return cnt == null ? 0 : cnt;
    }

    private FamilyVO toVO(Family family, long memberCount) {
        FamilyVO vo = new FamilyVO();
        vo.setId(family.getId());
        vo.setName(family.getName());
        vo.setCoverUrl(family.getCoverUrl());
        vo.setOwnerId(family.getOwnerId());
        vo.setMemberCount((int) memberCount);
        vo.setCreatedAt(family.getCreatedAt());
        return vo;
    }
}
