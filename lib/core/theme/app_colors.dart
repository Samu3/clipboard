import 'package:flutter/material.dart';

/// 应用颜色定义
class AppColors {
  AppColors._();

  // ==================== 主色 ====================
  static const Color L04 = Color(0xFF4A98F8);

  // ==================== 自适应颜色系统 ====================

  /// Black/08 - 浅色模式是黑色08，深色模式是白色08
  /// 使用方式：AppColors.black08(context)
  static Color black08(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0xCC000000) // 黑色 8% 透明度
        : const Color(0xCCFFFFFF); // 白色 8% 透明度
  }

  /// Black/12
  static Color black10(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0xFF000000) // 黑色 12%
        : const Color(0xFFFFFFFF); // 白色 12%
  }

  /// Black/16
  static Color black06(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0x99000000) // 黑色 16%
        : const Color(0x99FFFFFF); // 白色 16%
  }

  /// Black/24
  static Color black24(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0x3D000000) // 黑色 24%
        : const Color(0x3DFFFFFF); // 白色 24%
  }

  /// Black/32
  static Color black32(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0x52000000) // 黑色 32%
        : const Color(0x52FFFFFF); // 白色 32%
  }

  /// Black/48
  static Color black48(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0x7A000000) // 黑色 48%
        : const Color(0x7AFFFFFF); // 白色 48%
  }

  /// Black/60
  static Color black60(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0x99000000) // 黑色 60%
        : const Color(0x99FFFFFF); // 白色 60%
  }

  /// Black/100 - 完全不透明
  static Color black100(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0xFF000000) // 纯黑
        : const Color(0xFFFFFFFF); // 纯白
  }

  /// Black/100 - 完全不透明
  static Color white100(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
  }

  static Color bg_gray(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0xFFF7F7F7) // 纯黑
        : const Color(0xFF1C1D21); // 纯白
  }

  static Color button_gray(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? const Color(0xFF000000).withOpacity(0.06) // 纯黑
        : const Color(0xFFFFFFFF).withOpacity(0.06); // 纯白
  }

  // ==================== 语义化颜色 ====================

  // 浅色模式
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightSuccess = Color(0xFF388E3C);
  static const Color lightWarning = Color(0xFFF57C00);
  static const Color lightInfo = Color(0xFF1976D2);

  // 深色模式
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkDivider = Color(0xFF2C2C2C);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkSuccess = Color(0xFF81C784);
  static const Color darkWarning = Color(0xFFFFB74D);
  static const Color darkInfo = Color(0xFF64B5F6);

  // ==================== 功能颜色 ====================

  /// 水滴蓝色（喝水功能专用）
  static const Color waterBlue = Color(0xFF00BCD4);
  static const Color waterBlueLight = Color(0xFF4DD0E1);
  static const Color waterBlueDark = Color(0xFF0097A7);

  /// 图表颜色
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // 蓝色
    Color(0xFF4CAF50), // 绿色
    Color(0xFFFF9800), // 橙色
    Color(0xFF9C27B0), // 紫色
    Color(0xFFE91E63), // 粉色
    Color(0xFFFFEB3B), // 黄色
  ];
}

/// 扩展方法，方便使用
extension AppColorsExtension on BuildContext {
  /// 快速获取自适应颜色
  AppColorsHelper get color => AppColorsHelper(this);
}

/// 颜色辅助类
class AppColorsHelper {
  final BuildContext context;

  AppColorsHelper(this.context);

  /// Black/08 - 浅色模式是黑色08，深色模式是白色08
  Color get black08 => AppColors.black08(context);

  /// Black/12
  Color get black10 => AppColors.black10(context);

  /// Black/16
  Color get black06 => AppColors.black06(context);

  Color get L04 => AppColors.L04;

  Color get white100 => AppColors.white100(context);

  Color get bg_gray => AppColors.bg_gray(context);

  Color get button_gray => AppColors.button_gray(context);
}
