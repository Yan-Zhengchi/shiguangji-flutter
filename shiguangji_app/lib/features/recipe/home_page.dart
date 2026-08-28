import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
import 'widgets/category_nav_row.dart';
import 'widgets/recipe_card_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final feed = ref.watch(homeFeedProvider((categoryId: null, page: 1)));
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // 顶栏：标题 + 头像
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
              child: Row(
                children: [
                  const Text('食光记', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: const CircleAvatar(radius: 16, backgroundColor: AppColors.glassFill,
                        child: Icon(Icons.person, size: 18, color: AppColors.text2)),
                  ),
                ],
              ),
            ),
            // 搜索框（点击跳搜索页）；底部 40 = 与分类行、分类行与瀑布流的统一间距
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: GlassCard(
                  radius: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  blur: false,
                  child: Row(
                    children: const [
                      Icon(Icons.search, size: 18, color: AppColors.text2),
                      SizedBox(width: 8),
                      Text('搜索菜谱 / 食材', style: TextStyle(color: AppColors.text2, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            // 分类入口（玻璃图标 + 文字）；底部间距与上方搜索框一致
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: cats.when(
                data: (list) => CategoryNavRow(categories: list),
                loading: () => const SizedBox(height: 98),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            // 瀑布流
            Expanded(
              child: feed.when(
                data: (list) => list.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.glassFill,
                        onRefresh: () async => ref.refresh(homeFeedProvider((categoryId: null, page: 1)).future),
                        // 顶部内边距归零：分类行与瀑布流的实际间距就是上面统一的 40
                        child: RecipeWaterfall(
                          recipes: list,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => _errorState(e, () => ref.invalidate(homeFeedProvider((categoryId: null, page: 1)))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Text('还没有菜谱，去「新增」发布第一道吧',
            style: TextStyle(color: AppColors.text2, fontSize: 13)),
      );

  Widget _errorState(Object e, VoidCallback retry) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.text2, size: 40),
            const SizedBox(height: 10),
            Text('加载失败：$e', style: const TextStyle(color: AppColors.text2, fontSize: 12)),
            const SizedBox(height: 12),
            TextButton(onPressed: retry, child: const Text('重试', style: TextStyle(color: AppColors.blueBright))),
          ],
        ),
      );
}

