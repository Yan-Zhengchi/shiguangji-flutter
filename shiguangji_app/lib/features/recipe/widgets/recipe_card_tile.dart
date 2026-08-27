import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../shared/models.dart';

/// 瀑布流卡片（首页/分类/搜索/收藏/家庭通用）
class RecipeCardTile extends StatelessWidget {
  const RecipeCardTile({super.key, required this.recipe});
  final RecipeCardVO recipe;

  @override
  Widget build(BuildContext context) {
    final ratio = recipe.imgRatio ?? 0.9;
    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}'),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 1 / ratio,   // 高/宽 = ratio
                child: _image(),
              ),
            ),
            const SizedBox(height: 8),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1, height: 1.3)),
            ),
            const SizedBox(height: 6),
            // 作者 + 收藏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(recipe.authorName ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.text2)),
                  ),
                  const Icon(Icons.favorite, size: 12, color: AppColors.heart),
                  const SizedBox(width: 3),
                  Text('${recipe.favoriteCount}',
                      style: const TextStyle(fontSize: 11, color: AppColors.text2)),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final url = recipe.coverUrl;
    if (url == null || url.isEmpty) return const PhPlaceholder(emoji: '🍳');
    final full = ApiClient.assetUrl(url);
    return CachedNetworkImage(
      imageUrl: full,
      fit: BoxFit.cover,
      placeholder: (_, __) => const PhPlaceholder(),
      errorWidget: (_, __, ___) => const PhPlaceholder(),
    );
  }
}

/// 通用瀑布流（双列乱序）
class RecipeWaterfall extends StatelessWidget {
  const RecipeWaterfall({super.key, required this.recipes, this.shrinkWrap = false, this.padding});
  final List<RecipeCardVO> recipes;
  final bool shrinkWrap;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: padding ?? const EdgeInsets.fromLTRB(16, 6, 16, 14),
      itemCount: recipes.length,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (ctx, i) => RecipeCardTile(recipe: recipes[i]),
    );
  }
}
