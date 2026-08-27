import 'package:flutter/material.dart';

/// 设计令牌（亮色版：参考 bigmodel.cn 主页 —— 近白底 + 浅蓝/浅紫极光晕 + 白卡）
class AppColors {
  AppColors._();

  // 背景渐变（近白，带冷调）
  static const bgTop = Color(0xFFF7F8FC);
  static const bgBottom = Color(0xFFEDF0F7);

  // 极光晕（柔焦浅蓝 / 浅紫 / 淡青，缓慢漂移）
  static const auroraBlue = Color(0xFFB7CCF9);
  static const auroraPurple = Color(0xFFD6C9F7);
  static const auroraCyan = Color(0xFFC0E2F9);

  // 主色与渐变（白底可读的饱和蓝）
  static const primary = Color(0xFF2E7CF6);
  static const primaryGradB = Color(0xFF1B63D8);
  static const publishGradA = Color(0xFF4E97FF);
  static const publishGradB = Color(0xFF2E7CF6);

  // 文字（墨色系）
  static const text1 = Color(0xFF1B2436);   // 主文字
  static const text2 = Color(0xFF7C8AA5);   // 次文字
  static const text3 = Color(0xFF3E4A61);   // chips 文字
  static const body = Color(0xFF38435A);    // 正文/步骤

  // 强调色
  static const blueBright = Color(0xFF2E7CF6);   // 链接/强调蓝
  static const blueTip = Color(0xFF4E8DF6);      // 妙招文字
  static const orange = Color(0xFFFF8C42);      // 暖橙
  static const orangeTitle = Color(0xFFE07E2E);
  static const orangeBody = Color(0xFFB5713A);
  static const orangeMeta = Color(0xFF97765A);
  static const heart = Color(0xFFFF5A76);        // 收藏红粉

  // 卡片（白卡体系：微透白填充 + 墨色细描边，光晕可极轻微透出）
  static const glassFill = Color(0xF0FFFFFF);        // 白 94%
  static const glassFillWeak = Color(0xD9FFFFFF);    // 白 85%
  static const glassFillStrong = Color(0x121B2436);  // 墨 7%（头像底）
  static const glassFillField = Color(0x081B2436);   // 墨 3%（输入底）
  static const glassStroke = Color(0x141B2436);      // 墨 8%
  static const glassStrokeStrong = Color(0x291B2436);// 墨 16%

  // 阴影（柔和冷灰蓝）
  static const shadowCard = Color(0x14263E6E);   // rgba(38,62,110,.08)
  static const shadowBlue = Color(0x242E7CF6);
  static const shadowChip = Color(0x402E7CF6);   // rgba(46,124,246,.25)
}

ThemeData appTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.orange,
        surface: Colors.white,
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
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.glassFillWeak,
        side: BorderSide(color: AppColors.glassStroke),
        labelStyle: TextStyle(fontSize: 13, color: AppColors.text3),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFillField,
        hintStyle: TextStyle(color: AppColors.text2, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.glassStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.glassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
