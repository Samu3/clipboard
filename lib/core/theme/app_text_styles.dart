import 'package:flutter/material.dart';

/// 应用文字样式定义
class AppTextStyles {
  AppTextStyles._();

  // 基础字体
  static const String fontFamily = 'PingFang SC';

  // ==================== Display ====================
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    fontFamily: fontFamily,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    fontFamily: fontFamily,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    fontFamily: fontFamily,
  );

  // ==================== Headline ====================
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    fontFamily: fontFamily,
  );

  // ==================== Title ====================
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    fontFamily: fontFamily,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    fontFamily: fontFamily,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    fontFamily: fontFamily,
  );

  // ==================== Body ====================
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    fontFamily: fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    fontFamily: fontFamily,
  );

  // ==================== Label ====================
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    fontFamily: fontFamily,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );

  // ==================== 特殊用途 ====================

  /// AppBar标题
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    fontFamily: fontFamily,
  );

  /// 按钮文字
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    fontFamily: fontFamily,
  );

  /// 数字展示（大）
  static const TextStyle numberLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    fontFamily: fontFamily,
  );

  /// 数字展示（中）
  static const TextStyle numberMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    fontFamily: fontFamily,
  );

  /// 数字展示（小）
  static const TextStyle numberSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    fontFamily: fontFamily,
  );
}
