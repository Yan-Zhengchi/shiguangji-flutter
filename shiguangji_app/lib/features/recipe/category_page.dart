import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
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
            // 顶栏
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back, color: AppColors.text1)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: cats.when(
                        data: (list) => ListView(
                          scrollDirection: Axis.horizontal,
                          children: list.map((c) {
                            final active = c.id == categoryId;
                            return GestureDetector(
                              onTap: () => context.pushReplacement('/category/${c.id}'),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: active ? AppColors.primary : AppColors.glassFillWeak,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: active ? AppColors.primary : AppColors.glassStroke),
                                ),
                                child: Text(c.name,
                                    style: TextStyle(fontSize: 13,
                                        color: active ? Colors.white : AppColors.text3,
                                        fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                              ),
                            );
                          }).toList(),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],
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
