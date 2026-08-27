import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/providers.dart';

class FamiliesPage extends ConsumerStatefulWidget {
  const FamiliesPage({super.key});
  @override
  ConsumerState<FamiliesPage> createState() => _FamiliesPageState();
}

class _FamiliesPageState extends ConsumerState<FamiliesPage> {
  @override
  Widget build(BuildContext context) {
    final families = ref.watch(familiesProvider);
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.text1),
                    onPressed: () => context.pop()),
                const Text('家庭菜谱', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text1)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.add, color: AppColors.blueBright),
                    onPressed: () => _createFamily()),
              ]),
            ),
            Expanded(
              child: families.when(
                data: (list) => list.isEmpty
                    ? const Center(child: Text('还没有家庭，点右上角创建',
                        style: TextStyle(color: AppColors.text2, fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final f = list[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              blur: false,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  const Icon(Icons.family_restroom, color: AppColors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(f.name,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text1))),
                                  Text('${f.memberCount} 成员', style: const TextStyle(color: AppColors.text2, fontSize: 12)),
                                ]),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => _showInviteDialog(f.id, f.name),
                                    child: const Text('邀请成员', style: TextStyle(color: AppColors.blueBright, fontSize: 12)),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('加载失败：$e', style: const TextStyle(color: AppColors.text2))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFamily() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgBottom,
        title: const Text('创建家庭', style: TextStyle(color: AppColors.text1)),
        content: TextField(controller: ctrl, autofocus: true,
            style: const TextStyle(color: AppColors.text1),
            decoration: const InputDecoration(hintText: '家庭名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('创建', style: TextStyle(color: AppColors.blueBright))),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(familyRepoProvider).create(name);
      ref.invalidate(familiesProvider);
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _showInviteDialog(String familyId, String familyName) async {
    final ctrl = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgBottom,
        title: Text('邀请成员到「$familyName」', style: const TextStyle(color: AppColors.text1, fontSize: 16)),
        content: TextField(controller: ctrl, autofocus: true,
            style: const TextStyle(color: AppColors.text1),
            decoration: const InputDecoration(hintText: '输入用户名')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('邀请', style: TextStyle(color: AppColors.blueBright))),
        ],
      ),
    );
    if (username != null && username.isNotEmpty) {
      try {
        await ref.read(familyRepoProvider).invite(familyId, username: username);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('邀请成功')));
        ref.invalidate(familiesProvider);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('邀请失败：$e')));
      }
    }
  }
}
