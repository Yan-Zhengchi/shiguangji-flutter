import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';
import '../../shared/models.dart';

/// 新增 / 编辑菜谱页
class EditPage extends ConsumerStatefulWidget {
  const EditPage({super.key, this.recipeId});
  final String? recipeId;
  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _servings = TextEditingController(text: '2');
  final _cookMin = TextEditingController(text: '30');
  final _tips = TextEditingController();
  final _notes = TextEditingController();
  final _expText = TextEditingController();

  String? _categoryId;
  String? _coverUrl;
  int _difficulty = 2;
  final List<_IngredientRow> _ingredients = [];
  final List<TextEditingController> _steps = [];
  bool _loading = false;
  bool _loaded = false;   // 编辑模式预填完成标志

  @override
  void dispose() {
    for (final c in [_title, _desc, _servings, _cookMin, _tips, _notes, _expText]) {
      c.dispose();
    }
    for (final c in _steps) {
      c.dispose();
    }
    for (final i in _ingredients) {
      i.dispose();
    }
    super.dispose();
  }

  void _addIngredient() => setState(() => _ingredients.add(_IngredientRow()));
  void _removeIngredient(int i) => setState(() { _ingredients[i].dispose(); _ingredients.removeAt(i); });
  void _addStep() => setState(() => _steps.add(TextEditingController()));
  void _removeStep(int i) => setState(() { _steps[i].dispose(); _steps.removeAt(i); });

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (x == null) return;
    setState(() => _loading = true);
    try {
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(x.path, filename: x.name)});
      final r = await ApiClient.dio.post('uploads/image', data: form);
      final m = r.data as Map;
      if (m['code'] == 0) {
        setState(() => _coverUrl = m['data'].toString());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片上传失败')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _categoryId == null || _steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题、分类和至少一个步骤')));
      return;
    }
    setState(() => _loading = true);
    final body = {
      'title': _title.text.trim(),
      'categoryId': _categoryId,
      'coverUrl': _coverUrl,
      'description': _desc.text.trim(),
      'servings': int.tryParse(_servings.text) ?? 2,
      'cookMinutes': int.tryParse(_cookMin.text) ?? 30,
      'difficulty': _difficulty,
      'ingredients': _ingredients.where((r) => r.name.text.trim().isNotEmpty).map((r) => {
            'type': r.type, 'name': r.name.text.trim(), 'amount': r.amount.text.trim(),
          }).toList(),
      'steps': _steps.where((c) => c.text.trim().isNotEmpty).map((c) => c.text.trim()).toList(),
      'tips': _tips.text.trim().isEmpty ? null : _tips.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'experience': _expText.text.trim().isEmpty ? null : {'text': _expText.text.trim()},
    };
    try {
      final repo = ref.read(recipeRepoProvider);
      if (widget.recipeId == null) {
        await repo.publish(body);
      } else {
        await repo.update(widget.recipeId!, body);
      }
      ref.invalidate(homeFeedProvider((categoryId: null, page: 1)));
      ref.invalidate(hotProvider);
      if (widget.recipeId != null) ref.invalidate(detailProvider(widget.recipeId!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.recipeId == null ? '发布成功' : '修改成功')));
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败：$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    // 编辑模式：watch 详情，加载完成后预填一次
    if (widget.recipeId != null && !_loaded) {
      final d = ref.watch(detailProvider(widget.recipeId!));
      d.whenData((detail) {
        if (detail.title.isNotEmpty && !_loaded) {
          _loaded = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _prefill(detail);
          });
        }
      });
    }
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
                    onTap: () => context.pop(),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close, color: AppColors.text1)),
                  ),
                  const SizedBox(width: 4),
                  Text(widget.recipeId == null ? '新增菜谱' : '编辑菜谱',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text1)),
                  const Spacer(),
                  TextButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blueBright))
                        : const Text('发布', style: TextStyle(color: AppColors.blueBright, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _Card(child: TextField(
                    controller: _title, style: const TextStyle(color: AppColors.text1),
                    decoration: const InputDecoration(hintText: '菜谱标题', border: InputBorder.none),
                  )),
                  const SizedBox(height: 12),
                  // 封面
                  _Card(child: GestureDetector(
                    onTap: _pickImage,
                    child: SizedBox(
                      height: 120,
                      child: _coverUrl == null
                          ? const Center(child: Text('+ 选择封面图', style: TextStyle(color: AppColors.text2, fontSize: 13)))
                          : ClipRRect(borderRadius: BorderRadius.circular(14),
                              child: Image.network(ApiClient.assetUrl(_coverUrl!),
                                  fit: BoxFit.cover, width: double.infinity, height: 120,
                                  errorBuilder: (_, __, ___) => const ColoredBox(
                                      color: Color(0xFF1B3358), child: SizedBox.expand()))),
                    ),
                  )),
                  const SizedBox(height: 12),
                  // 分类
                  _Card(child: cats.when(
                    data: (list) => DropdownButton<String>(
                      value: _categoryId, underline: const SizedBox(),
                      dropdownColor: AppColors.bgBottom,
                      hint: const Text('选择分类', style: TextStyle(color: AppColors.text2, fontSize: 14)),
                      items: list.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name,
                          style: const TextStyle(color: AppColors.text1)))).toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                    error: (_, __) => const Text('分类加载失败', style: TextStyle(color: AppColors.heart)),
                  )),
                  const SizedBox(height: 12),
                  _Card(child: TextField(
                    controller: _desc, maxLines: 2,
                    style: const TextStyle(color: AppColors.text1, fontSize: 13),
                    decoration: const InputDecoration(hintText: '一句话简介', border: InputBorder.none),
                  )),
                  const SizedBox(height: 12),
                  // 分量 / 时间 / 难度
                  _Card(child: Column(children: [
                    _numField(_servings, '人份'),
                    const Divider(height: 1, color: AppColors.glassStroke),
                    _numField(_cookMin, '分钟'),
                    const Divider(height: 1, color: AppColors.glassStroke),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        const Text('难度', style: TextStyle(color: AppColors.text2, fontSize: 14)),
                        const SizedBox(width: 14),
                        Expanded(child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('简单')),
                            ButtonSegment(value: 2, label: Text('中等')),
                            ButtonSegment(value: 3, label: Text('困难')),
                          ],
                          selected: {_difficulty},
                          onSelectionChanged: (s) => setState(() => _difficulty = s.first),
                          style: const ButtonStyle(visualDensity: VisualDensity(vertical: -2, horizontal: -2)),
                        )),
                      ]),
                    ),
                  ])),
                  const SizedBox(height: 12),
                  // 食材
                  _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('食材', style: TextStyle(color: AppColors.text1, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    ..._ingredients.asMap().entries.map((e) => _ingredientEditor(e.key, e.value)),
                    TextButton.icon(onPressed: _addIngredient,
                        icon: const Icon(Icons.add, size: 16, color: AppColors.blueBright),
                        label: const Text('添加食材', style: TextStyle(color: AppColors.blueBright, fontSize: 13))),
                  ])),
                  const SizedBox(height: 12),
                  // 步骤
                  _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('做法步骤', style: TextStyle(color: AppColors.text1, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 10),
                    ..._steps.asMap().entries.map((e) => _stepEditor(e.key, e.value)),
                    TextButton.icon(onPressed: _addStep,
                        icon: const Icon(Icons.add, size: 16, color: AppColors.blueBright),
                        label: const Text('添加步骤', style: TextStyle(color: AppColors.blueBright, fontSize: 13))),
                  ])),
                  const SizedBox(height: 12),
                  _Card(child: TextField(
                    controller: _tips, maxLines: 2,
                    style: const TextStyle(color: AppColors.text1, fontSize: 13),
                    decoration: const InputDecoration(hintText: '妙招（可选）', border: InputBorder.none),
                  )),
                  const SizedBox(height: 12),
                  _Card(child: TextField(
                    controller: _notes, maxLines: 3,
                    style: const TextStyle(color: AppColors.text1, fontSize: 13),
                    decoration: const InputDecoration(hintText: '注意事项（每行一条，可选）', border: InputBorder.none),
                  )),
                  const SizedBox(height: 12),
                  _Card(child: TextField(
                    controller: _expText, maxLines: 2,
                    style: const TextStyle(color: AppColors.orangeBody, fontSize: 13),
                    decoration: const InputDecoration(hintText: '吃一堑长一智（可选）', border: InputBorder.none),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _prefill(RecipeDetailVO d) {
    if (d.title.isEmpty) return;
    _title.text = d.title;
    _desc.text = d.description ?? '';
    _coverUrl = d.images.isNotEmpty ? d.images.first : null;
    _servings.text = (d.servings.contains('人份')
        ? d.servings.replaceAll(RegExp(r'\s*人份'), '') : '2');
    _cookMin.text = '${d.cookMinutes ?? 30}';
    _difficulty = d.difficulty == '简单'
        ? 1
        : (d.difficulty == '困难' ? 3 : 2);
    _tips.text = d.tips ?? '';
    _notes.text = d.notes.join('\n');
    _expText.text = d.experience?.text ?? '';
    // 分类匹配：需后端返回 categoryId；当前 detail 无 categoryId 字段，跳过精确匹配，
    // 让用户在下拉里重选。正式版可让详情接口带 categoryId。
    setState(() {});
  }

  Widget _numField(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label, style: const TextStyle(color: AppColors.text2, fontSize: 14)),
          const Spacer(),
          SizedBox(width: 80, child: TextField(
            controller: c, keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.text1, fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          )),
        ]),
      );

  Widget _ingredientEditor(int idx, _IngredientRow r) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() => r.type = r.type == 1 ? 2 : 1),
            child: Container(
              width: 44, height: 32, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: r.type == 1 ? AppColors.primary.withOpacity(.2) : AppColors.orange.withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: r.type == 1 ? AppColors.primary : AppColors.orange),
              ),
              child: Text(r.type == 1 ? '主料' : '配料',
                  style: TextStyle(fontSize: 11, color: r.type == 1 ? AppColors.blueBright : AppColors.orangeTitle)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: TextField(
            controller: r.name, style: const TextStyle(color: AppColors.text1, fontSize: 13),
            decoration: const InputDecoration(hintText: '食材名', isDense: true, border: InputBorder.none))),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: TextField(
            controller: r.amount, style: const TextStyle(color: AppColors.text2, fontSize: 13),
            decoration: const InputDecoration(hintText: '用量', isDense: true, border: InputBorder.none))),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.text2),
            onPressed: () => _removeIngredient(idx), padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
      );

  Widget _stepEditor(int idx, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22, height: 22, margin: const EdgeInsets.only(top: 8),
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: c, maxLines: null,
            style: const TextStyle(color: AppColors.body, fontSize: 13, height: 1.5),
            decoration: const InputDecoration(hintText: '步骤内容', border: InputBorder.none))),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.text2),
            onPressed: () => _removeStep(idx), padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: child,
      );
}

class _IngredientRow {
  int type = 1;   // 1 主料 2 配料
  final TextEditingController name = TextEditingController();
  final TextEditingController amount = TextEditingController();
  void dispose() { name.dispose(); amount.dispose(); }
}
