import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
import 'widgets/category_nav_row.dart';
import 'widgets/recipe_card_tile.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key, required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider);
    final feed = ref.watch(homeFeedProvider((categoryId: categoryId, page: 1)));
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // 顶栏：返回箭头独占一行
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back, color: AppColors.text1)),
                  ),
                ],
              ),
            ),
            // 分类入口：等分铺满屏宽，当前分类高亮
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: cats.when(
                data: (list) => Row(
                  children: [
                    for (final c in list)
                      Expanded(
                        child: CategoryIconTile(
                          name: c.name,
                          asset: categoryAssetOf(c.name),
                          selected: c.id == categoryId,
                          onTap: () => context.pushReplacement('/category/${c.id}'),
                        ),
                      ),
                  ],
                ),
                loading: () => const SizedBox(height: 84),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: feed.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('该分类下还没有菜谱',
                        style: TextStyle(color: AppColors.text2, fontSize: 13)))
                    : RecipeWaterfall(recipes: list),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('加载失败：$e',
                    style: const TextStyle(color: AppColors.text2, fontSize: 12))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
