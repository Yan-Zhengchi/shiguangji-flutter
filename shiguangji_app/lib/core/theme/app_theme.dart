import 'package:flutter/material.dart';

/// 设计令牌（1:1 取自设计稿《食光记-深色玻璃版》CSS 变量）
class AppColors {
  AppColors._();

  // 背景渐变
  static const bgTop = Color(0xFF050F26);
  static const bgBottom = Color(0xFF0F1F40);

  // 主色与渐变
  static const primary = Color(0xFF2E8CFF);
  static const primaryGradB = Color(0xFF1A6AF2);
  static const publishGradA = Color(0xFF47A3FF);
  static const publishGradB = Color(0xFF1E70E0);

  // 文字
  static const text1 = Color(0xFFF2F5FA);   // 主文字
  static const text2 = Color(0xFF8AA1BC);   // 次文字
  static const text3 = Color(0xFFC9D6E8);   // chips 文字
  static const body = Color(0xFFB4C4DA);    // 正文/步骤

  // 强调色
  static const blueBright = Color(0xFF5BA0FF);   // 亮蓝
  static const blueTip = Color(0xFF7FB8FF);      // 妙招文字
  static const orange = Color(0xFFFF8C42);      // 暖橙
  static const orangeTitle = Color(0xFFFFC38F);
  static const orangeBody = Color(0xFFE8B47A);
  static const orangeMeta = Color(0xFFF2D8B8);
  static const heart = Color(0xFFFF6B81);        // 收藏红粉

  // 玻璃填充（白 alpha）
  static const glassFill = Color(0x1FFFFFFF);       // white 12%
  static const glassFillWeak = Color(0x1AFFFFFF);   // white 10%
  static const glassFillStrong = Color(0x26FFFFFF); // white 15%
  static const glassFillField = Color(0x0DFFFFFF);  // white 5%
  static const glassStroke = Color(0x29FFFFFF);     // white 16%
  static const glassStrokeStrong = Color(0x40FFFFFF); // white 25%

  // 阴影
  static const shadowCard = Color(0x1F2E486B);   // rgba(46,72,107,.12)
  static const shadowBlue = Color(0x1F2E6EA6);
  static const shadowChip = Color(0x592E8CFF);   // rgba(46,140,255,.35)
}

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.orange,
        surface: AppColors.bgBottom,
        onSurface: AppColors.text1,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text1, height: 1.3),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text1),
        bodyMedium: TextStyle(fontSize: 13, height: 1.6, color: AppColors.body),
        bodySmall: TextStyle(fontSize: 12, height: 1.5, color: AppColors.body),
        labelSmall: TextStyle(fontSize: 11, color: AppColors.text2, letterSpacing: .3),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassFillWeak,
        side: const BorderSide(color: AppColors.glassStroke),
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.text3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        hintStyle: const TextStyle(color: AppColors.text2, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
