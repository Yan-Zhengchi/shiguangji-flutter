import 'dart:math' as math;
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
    this.blur = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color fill;
  final Color stroke;
  final bool weak;

  /// 是否启用真实毛玻璃（BackdropFilter）。它每帧都要重新采样底层做高斯模糊，
  /// 大面积/多卡片堆叠是掉帧大户；卡片底色近纯色（表单页）时建议关掉，
  /// 半透明填充的视觉效果几乎无差。
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final container = Container(
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
    );
    if (!blur) {
      // RepaintBoundary：滚动时整卡作为独立图层缓存平移，避免反复重绘
      return RepaintBoundary(child: container);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: container,
      ),
    );
  }
}

/// 页面背景：近白渐变 + 缓慢漂移的浅蓝/浅紫极光晕（参考 bigmodel.cn 主页）
/// 光晕用大半径径向渐变模拟高斯柔焦（无 BackdropFilter 开销），
/// 每颗光晕独立 RepaintBoundary，动画帧只重绘光晕层本身。
class GradientBackground extends StatefulWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 近白底渐变
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgTop, AppColors.bgBottom],
            ),
          ),
        ),
        // 漂移光晕（利萨如轨迹，幅度小、周期长 → 观感是"缓慢呼吸"）
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value * 2 * math.pi;
            return Stack(
              children: [
                // 浅蓝（左上）
                Positioned(
                  top: -150 + 26 * math.sin(t),
                  left: -120 + 34 * math.cos(t * .8),
                  child: _blob(AppColors.auroraBlue, 400, .80),
                ),
                // 浅紫（右下）
                Positioned(
                  bottom: -100 + 22 * math.sin(t * 1.15 + 2.1),
                  right: -80 + 28 * math.cos(t * .65 + 1.2),
                  child: _blob(AppColors.auroraPurple, 360, .75),
                ),
                // 淡青（中部小晕）
                Positioned(
                  top: 170 + 18 * math.sin(t * .9 + 4.0),
                  right: 70 + 20 * math.cos(t * .7),
                  child: _blob(AppColors.auroraCyan, 260, .55),
                ),
              ],
            );
          },
        ),
        // 内容（Material 包裹：TextField 等组件需要 Material 祖先）
        Positioned.fill(
          child: Material(type: MaterialType.transparency, child: widget.child),
        ),
      ],
    );
  }

  Widget _blob(Color color, double size, double opacity) => RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
            ),
          ),
        ),
      );
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
              colors: [Color(0xFFE3EAF6), Color(0xFFD2DCEC)]),
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
