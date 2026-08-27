import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
import '../../shared/models.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.recipeId});
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(detailProvider(recipeId));
    return GradientBackground(
      child: SafeArea(
        child: detail.when(
          data: (d) => _DetailBody(d: d, recipeId: recipeId, ref: ref),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => _ErrorView(e: e, onRetry: () => ref.invalidate(detailProvider(recipeId))),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.d, required this.recipeId, required this.ref});
  final RecipeDetailVO d;
  final String recipeId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // 顶栏（返回 + 编辑）
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(
                  children: [
                    _CircleAction(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    const Spacer(),
                    if (TokenStore.instance.isAuthed)
                      _CircleAction(icon: Icons.edit_outlined, onTap: () => context.push('/recipe/$recipeId/edit')),
                  ],
                ),
              ),
            ),
            // 封面图
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _coverImage(d.images.isNotEmpty ? d.images.first : d.id),
                  ),
                ),
              ),
            ),
            // 标题 + 作者
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1, height: 1.3)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.text2),
                        const SizedBox(width: 4),
                        Text(d.authorName, style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                        const SizedBox(width: 14),
                        const Icon(Icons.favorite, size: 14, color: AppColors.heart),
                        const SizedBox(width: 3),
                        Text('${d.favoriteCount}', style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                        const SizedBox(width: 14),
                        const Icon(Icons.visibility_outlined, size: 14, color: AppColors.text2),
                        const SizedBox(width: 3),
                        Text('${d.viewCount}', style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 信息 chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _InfoChip(icon: Icons.schedule, text: '${d.cookMinutes ?? 30} 分钟'),
                    _InfoChip(icon: Icons.local_fire_department_outlined, text: d.difficulty),
                    _InfoChip(icon: Icons.restaurant, text: d.servings),
                    if (d.categoryName != null) _InfoChip(icon: Icons.category_outlined, text: d.categoryName!),
                  ],
                ),
              ),
            ),
            // 简介
            if (d.description != null && d.description!.isNotEmpty)
              SliverToBoxAdapter(
                child: _Section(child: Text(d.description!, style: const TextStyle(color: AppColors.body, height: 1.6))),
              ),
            // 食材
            SliverToBoxAdapter(child: _IngredientsBlock(ingredients: d.ingredients)),
            // 工具
            if (d.tools.isNotEmpty)
              SliverToBoxAdapter(
                child: _Section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('烹饪工具'),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: d.tools.map((t) => _ToolChip(name: t)).toList()),
                    ],
                  ),
                ),
              ),
            // 步骤
            SliverToBoxAdapter(child: _StepsBlock(steps: d.steps)),
            // 妙招
            if (d.tips != null && d.tips!.isNotEmpty)
              SliverToBoxAdapter(child: _TipCard(text: d.tips!)),
            // 注意事项
            if (d.notes.isNotEmpty)
              SliverToBoxAdapter(
                child: _Section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('注意事项'),
                      const SizedBox(height: 8),
                      ...d.notes.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('·  ', style: TextStyle(color: AppColors.blueBright)),
                          Expanded(child: Text(n, style: const TextStyle(color: AppColors.body, height: 1.5))),
                        ]),
                      )),
                    ],
                  ),
                ),
              ),
            // 吃一堑长一智（暖橙卡）
            if (d.experience != null && (d.experience!.text?.isNotEmpty ?? false))
              SliverToBoxAdapter(child: _ExperienceCard(exp: d.experience!)),
            // 图集
            if (d.images.length > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('菜谱图集'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: d.images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(width: 120, height: 120, child: _coverImage(d.images[i])),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        // 收藏浮动按钮
        Positioned(
          right: 16, bottom: 16,
          child: _FavoriteFAB(recipeId: recipeId, favorited: d.favorite, ref: ref),
        ),
      ],
    );
  }

  Widget _coverImage(String urlOrId) {
    final url = ApiClient.assetUrl(urlOrId);
    return CachedImage(url: url);
  }
}

class CachedImage extends StatelessWidget {
  const CachedImage({super.key, required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => const ColoredBox(color: Color(0xFF1B3358), child: SizedBox.expand()),
      errorWidget: (_, __, ___) => const PhPlaceholder(emoji: '🍽️', size: 40),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: GlassCard(padding: const EdgeInsets.all(14), child: child),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1));
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.glassFillWeak,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassStroke),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppColors.blueBright),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
        ]),
      );
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.glassFillField,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassStroke),
        ),
        child: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
      );
}

class _IngredientsBlock extends StatelessWidget {
  const _IngredientsBlock({required this.ingredients});
  final List<IngredientVO> ingredients;
  @override
  Widget build(BuildContext context) {
    final main = ingredients.where((i) => i.type == '主料').toList();
    final sub = ingredients.where((i) => i.type == '配料').toList();
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (main.isNotEmpty) ...[
            const _SectionTitle('主料'),
            const SizedBox(height: 8),
            ...main.map(_ingredientRow),
            if (sub.isNotEmpty) const SizedBox(height: 14),
          ],
          if (sub.isNotEmpty) ...[
            const _SectionTitle('配料'),
            const SizedBox(height: 8),
            ...sub.map(_ingredientRow),
          ],
        ],
      ),
    );
  }

  Widget _ingredientRow(IngredientVO i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(i.name, style: const TextStyle(color: AppColors.text1, fontSize: 13))),
            Expanded(flex: 2, child: Text(i.amount ?? '', textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.text2, fontSize: 12))),
          ],
        ),
      );
}

class _StepsBlock extends StatelessWidget {
  const _StepsBlock({required this.steps});
  final List<String> steps;
  @override
  Widget build(BuildContext context) => _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('做法步骤'),
            const SizedBox(height: 10),
            ...steps.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24, height: 24, alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value, style: const TextStyle(color: AppColors.body, height: 1.6))),
              ]),
            )),
          ],
        ),
      );
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x1F2E8CFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x592E8CFF)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.blueTip),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(color: AppColors.blueTip, height: 1.5, fontSize: 13))),
          ]),
        ),
      );
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.exp});
  final ExperienceVO exp;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.orange.withOpacity(.35)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.auto_awesome, size: 16, color: AppColors.orangeTitle),
              SizedBox(width: 6),
              Text('吃一堑 长一智', style: TextStyle(color: AppColors.orangeTitle, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Text(exp.text ?? '', style: const TextStyle(color: AppColors.orangeBody, height: 1.6, fontSize: 13)),
            if (exp.happenedAt != null) ...[
              const SizedBox(height: 6),
              Text(exp.happenedAt!, style: const TextStyle(color: AppColors.orangeMeta, fontSize: 11)),
            ],
          ]),
        ),
      );
}

class _FavoriteFAB extends ConsumerWidget {
  const _FavoriteFAB({required this.recipeId, required this.favorited, required this.ref});
  final String recipeId;
  final bool favorited;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TokenStore.instance.isAuthed) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () async {
        if (favorited) {
          await ref.read(favoriteRepoProvider).unfavorite(recipeId);
        } else {
          await ref.read(favoriteRepoProvider).favorite(recipeId);
        }
        ref.invalidate(detailProvider(recipeId));
        ref.invalidate(favoritesProvider);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: favorited
              ? [AppColors.heart, AppColors.heart]
              : [AppColors.publishGradA, AppColors.publishGradB]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: AppColors.shadowChip, blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(favorited ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(favorited ? '已收藏' : '收藏', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: AppColors.glassFill, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: AppColors.text1),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.e, required this.onRetry});
  final Object e;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: AppColors.text2, size: 40),
          const SizedBox(height: 10),
          Text('加载失败：$e', style: const TextStyle(color: AppColors.text2, fontSize: 12)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('重试', style: TextStyle(color: AppColors.blueBright))),
        ]),
      );
}
