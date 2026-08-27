import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 玻璃卡片：还原设计稿公式
///   fill: 白 12%  +  stroke: 白 16%  +  backdrop-blur 16  +  双阴影 + 内高光
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
    this.fill = AppColors.glassFill,
    this.stroke = AppColors.glassStroke,
    this.weak = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color fill;
  final Color stroke;
  final bool weak;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: weak ? AppColors.glassFillWeak : fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: stroke),
            boxShadow: const [
              BoxShadow(color: AppColors.shadowCard, blurRadius: 20, offset: Offset(0, 6)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 页面背景：深色渐变 + 暖橙/亮蓝光斑（光斑用径向渐变模拟柔光，无需 blur）
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child, this.showWarmGlow = true});

  final Widget child;
  final bool showWarmGlow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 渐变背景
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgTop, AppColors.bgBottom],
            ),
          ),
        ),
        // 暖橙光晕（左上）
        if (showWarmGlow)
          Positioned(
            top: -120, left: -100,
            child: Container(
              width: 380, height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.orange.withOpacity(.55), AppColors.orange.withOpacity(0)],
                ),
              ),
            ),
          ),
        // 亮蓝光晕（右下）
        Positioned(
          bottom: -80, right: -60,
          child: Container(
            width: 340, height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [AppColors.blueBright.withOpacity(.35), AppColors.blueBright.withOpacity(0)],
              ),
            ),
          ),
        ),
        // 内容（Material 包裹：TextField 等组件需要 Material 祖先）
        Positioned.fill(
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ],
    );
  }
}

/// 圆形渐变占位图（菜品图未加载/失败时）
class PhPlaceholder extends StatelessWidget {
  const PhPlaceholder({super.key, this.emoji = '🍳', this.size = 44});
  final String emoji;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1B3358), Color(0xFF25406B)]),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: size)),
      );
}

/// 通用骨架占位（加载中）
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width = double.infinity, this.height = 14, this.radius = 8});
  final double width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: AppColors.glassFillWeak,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// 数学工具
double imgRatioFromId(dynamic id) {
  final n = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
  return 0.75 + (n % 20) * 0.025;   // 与后端公式一致
}
