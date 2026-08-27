import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models.dart';

/// 分类名 → 图标资源（ASCII 文件名，规避中文资源路径在各端的兼容坑）
const _categoryAssets = <String, String>{
  '凉菜': 'assets/categories/liangcai.png',
  '热菜': 'assets/categories/recai.png',
  '鱼虾': 'assets/categories/yuxia.png',
  '肉类': 'assets/categories/roulei.png',
  '蔬菜': 'assets/categories/shucai.png',
};

/// 供外部（分类页等）按分类名取图标资源
String? categoryAssetOf(String name) => _categoryAssets[name];

/// 首页分类入口：玻璃图标块在上、名称在下，点击整块进分类页。
/// 等分铺满屏宽（居中），块尺寸随手机宽度自适应。
class CategoryNavRow extends StatelessWidget {
  const CategoryNavRow({super.key, required this.categories});

  final List<CategoryVO> categories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final c in categories)
            Expanded(
              child: CategoryIconTile(
                name: c.name,
                asset: _categoryAssets[c.name],
                onTap: () => context.push('/category/${c.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

/// 玻璃图标块（首页/分类页共用）：图标在上、名称在下，整块可点，按压缩放反馈
class CategoryIconTile extends StatefulWidget {
  const CategoryIconTile({
    super.key,
    required this.name,
    required this.onTap,
    this.asset,
    this.selected = false,
  });

  final String name;
  final String? asset;
  final VoidCallback onTap;

  /// 选中态：主色描边 + 主色文字 + 淡蓝光晕（分类页标当前分类用）
  final bool selected;

  @override
  State<CategoryIconTile> createState() => _CategoryIconTileState();
}

class _CategoryIconTileState extends State<CategoryIconTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,   // 图标 + 文字整体可点
      child: AnimatedScale(
        scale: _pressed ? .92 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 方形玻璃块：尺寸跟随列宽自适应（平板等宽屏封顶 76）
              LayoutBuilder(
                builder: (context, cons) {
                  final side = cons.maxWidth > 76 ? 76.0 : cons.maxWidth;
                  return _glassTile(side);
                },
              ),
              const SizedBox(height: 6),
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.selected ? AppColors.primary : AppColors.text3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 液态玻璃块：白玻璃渐变底（左上亮 → 右下透）+ 顶部内高光 + 白描边 + 柔投影
  Widget _glassTile(double side) {
    final radius = BorderRadius.circular(side * .31);
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF2FFFFFF), Color(0xB3FFFFFF)],   // 白 95% → 70%
        ),
        border: Border.fromBorderSide(BorderSide(
          color: widget.selected
              ? AppColors.primary.withValues(alpha: .45)
              : const Color(0xCCFFFFFF),
          width: widget.selected ? 1.4 : 1.2,
        )),
        boxShadow: [
          const BoxShadow(color: Color(0x1A263E6E), blurRadius: 14, offset: Offset(0, 6)),
          // 选中态叠加淡蓝光晕
          if (widget.selected)
            const BoxShadow(color: Color(0x332E7CF6), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // 顶部内高光：模拟玻璃弧面反光
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [const Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                  stops: const [0, .85],
                ),
              ),
            ),
          ),
          Center(
            child: widget.asset == null
                ? Text('🍽️', style: TextStyle(fontSize: side * .46))
                : Image.asset(
                    widget.asset!,
                    height: side * .58,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Text('🍽️', style: TextStyle(fontSize: side * .46)),
                  ),
          ),
        ],
      ),
    );
  }
}
