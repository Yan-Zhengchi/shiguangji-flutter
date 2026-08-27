import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
import 'widgets/recipe_card_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  String? _keyword;
  final _focus = FocusNode();

  void _submit(String kw) {
    final k = kw.trim();
    if (k.isEmpty) return;
    setState(() => _keyword = k);
    ref.invalidate(searchProvider(k));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hot = ref.watch(hotKeywordsProvider);
    final history = ref.watch(searchHistoryProvider);
    final results = _keyword == null ? null : ref.watch(searchProvider(_keyword!));
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back, color: AppColors.text1)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GlassCard(
                      radius: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _submit,
                        style: const TextStyle(color: AppColors.text1, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: '搜索菜谱 / 食材',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: AppColors.text2, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results == null
                  ? _landing(hot, history)
                  : results!.when(
                      data: (list) => list.isEmpty
                          ? _centerHint('没有找到「$_keyword」相关菜谱')
                          : RecipeWaterfall(recipes: list),
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (e, _) => _centerHint('搜索失败：$e'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _landing(AsyncValue<List<String>> hot, AsyncValue<List<String>> history) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      children: [
        if (history.value?.isNotEmpty ?? false) ...[
          Row(children: const [
            Icon(Icons.history, size: 16, color: AppColors.text2),
            SizedBox(width: 6),
            Text('搜索历史', style: TextStyle(color: AppColors.text2, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
            children: (history.value ?? []).map((k) => _keywordChip(k, onTap: () { _ctrl.text = k; _submit(k); })).toList()),
          const SizedBox(height: 20),
        ],
        Row(children: const [
          Icon(Icons.local_fire_department_outlined, size: 16, color: AppColors.orange),
          SizedBox(width: 6),
          Text('热搜词', style: TextStyle(color: AppColors.text2, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8,
          children: (hot.value ?? ['红烧肉', '番茄炒蛋', '糖醋排骨', '清蒸鱼', '麻婆豆腐'])
              .map((k) => _keywordChip(k, hot: true, onTap: () { _ctrl.text = k; _submit(k); })).toList()),
      ],
    );
  }

  Widget _keywordChip(String text, {bool hot = false, VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hot ? AppColors.orange.withOpacity(.12) : AppColors.glassFillWeak,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hot ? AppColors.orange.withOpacity(.35) : AppColors.glassStroke),
          ),
          child: Text(text, style: TextStyle(fontSize: 12, color: hot ? AppColors.orangeTitle : AppColors.text3)),
        ),
      );

  Widget _centerHint(String text) => Center(child: Text(text, style: const TextStyle(color: AppColors.text2, fontSize: 13)));
}
