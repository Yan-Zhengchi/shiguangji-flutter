import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../recipe/widgets/recipe_card_tile.dart';
import '../../data/providers.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider);
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            _TopBar(title: '我的收藏', onBack: () => context.pop()),
            Expanded(
              child: fav.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('还没有收藏菜谱',
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text1), onPressed: onBack),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text1)),
        ]),
      );
}
