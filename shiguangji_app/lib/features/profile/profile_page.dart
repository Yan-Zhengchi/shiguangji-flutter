import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/token_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
import '../recipe/widgets/recipe_card_tile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final recipes = ref.watch(userRecipesProvider);
    final families = ref.watch(familiesProvider);
    return GradientBackground(
      child: SafeArea(
        child: profile.when(
          data: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // 资料玻璃卡
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  CircleAvatar(radius: 30, backgroundColor: AppColors.glassFillStrong,
                    child: Text((p.nickname.isNotEmpty ? p.nickname : '?')[0],
                        style: const TextStyle(fontSize: 26, color: AppColors.text1))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text1)),
                      const SizedBox(height: 4),
                      Text('@${p.username}', style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.text2, size: 18),
                    onPressed: () => _editNickname(context, ref, p.nickname),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              // 统计行
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  _stat(p.stats.recipeCount, '菜谱', () => {}),
                  _divider(),
                  _stat(p.stats.favoriteCount, '收藏', () => context.push('/favorites')),
                  _divider(),
                  _stat(p.stats.familyCount, '家庭', () => context.push('/families')),
                ]),
              ),
              const SizedBox(height: 18),
              // 个人菜谱（横滑）
              const Text('我的菜谱', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: recipes.when(
                  data: (list) => list.isEmpty
                      ? const Center(child: Text('还没有发布菜谱',
                          style: TextStyle(color: AppColors.text2, fontSize: 12)))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => SizedBox(
                            width: 150,
                            child: RecipeCardTile(recipe: list[i]),
                          ),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 18),
              // 家庭菜谱
              Row(children: [
                const Text('家庭菜谱', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1)),
                const Spacer(),
                TextButton(onPressed: () => context.push('/families'),
                    child: const Text('全部 ›', style: TextStyle(color: AppColors.blueBright, fontSize: 12))),
              ]),
              const SizedBox(height: 8),
              families.when(
                data: (list) => list.isEmpty
                    ? const Text('还没有家庭', style: TextStyle(color: AppColors.text2, fontSize: 12))
                    : Column(children: list.map((f) => GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          const Icon(Icons.family_restroom, color: AppColors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f.name, style: const TextStyle(color: AppColors.text1, fontSize: 14))),
                          Text('${f.memberCount} 人', style: const TextStyle(color: AppColors.text2, fontSize: 12)),
                        ]),
                      )).toList()),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              // 登出
              TextButton.icon(
                onPressed: () async {
                  await TokenStore.instance.clear();
                  ref.invalidate(profileProvider);
                  ref.invalidate(favoritesProvider);
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, color: AppColors.heart, size: 18),
                label: const Text('退出登录', style: TextStyle(color: AppColors.heart, fontSize: 14)),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('加载失败：$e', style: const TextStyle(color: AppColors.text2))),
        ),
      ),
    );
  }

  Widget _stat(int n, String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(children: [
            Text('$n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text1)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.text2)),
          ]),
        ),
      );

  Widget _divider() => Container(width: 1, height: 28, color: AppColors.glassStroke);

  Future<void> _editNickname(BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgBottom,
        title: const Text('修改昵称', style: TextStyle(color: AppColors.text1)),
        content: TextField(controller: ctrl, autofocus: true,
            style: const TextStyle(color: AppColors.text1)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('保存', style: TextStyle(color: AppColors.blueBright))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(userRepoProvider).update(nickname: result);
      await TokenStore.instance.setProfile(nickname: result);
      ref.invalidate(profileProvider);
    }
  }
}
