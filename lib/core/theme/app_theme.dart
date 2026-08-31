import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// 应用主题配置 - 只支持亮色/暗色模式
class AppTheme {
  AppTheme._();

  // ==================== 浅色主题 ====================

  /// 浅色主题
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.L04,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: AppColors.lightTextPrimary,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.lightSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.L04, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightError),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge
            .copyWith(color: AppColors.lightTextPrimary),
        displayMedium: AppTextStyles.displayMedium
            .copyWith(color: AppColors.lightTextPrimary),
        displaySmall: AppTextStyles.displaySmall
            .copyWith(color: AppColors.lightTextPrimary),
        headlineLarge: AppTextStyles.headlineLarge
            .copyWith(color: AppColors.lightTextPrimary),
        headlineMedium: AppTextStyles.headlineMedium
            .copyWith(color: AppColors.lightTextPrimary),
        headlineSmall: AppTextStyles.headlineSmall
            .copyWith(color: AppColors.lightTextPrimary),
        titleLarge: AppTextStyles.titleLarge
            .copyWith(color: AppColors.lightTextPrimary),
        titleMedium: AppTextStyles.titleMedium
            .copyWith(color: AppColors.lightTextPrimary),
        titleSmall: AppTextStyles.titleSmall
            .copyWith(color: AppColors.lightTextPrimary),
        bodyLarge:
            AppTextStyles.bodyLarge.copyWith(color: AppColors.lightTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.lightTextPrimary),
        bodySmall: AppTextStyles.bodySmall
            .copyWith(color: AppColors.lightTextSecondary),
        labelLarge: AppTextStyles.labelLarge
            .copyWith(color: AppColors.lightTextPrimary),
        labelMedium: AppTextStyles.labelMedium
            .copyWith(color: AppColors.lightTextSecondary),
        labelSmall: AppTextStyles.labelSmall
            .copyWith(color: AppColors.lightTextSecondary),
      ),
    );
  }

  // ==================== 深色主题 ====================

  /// 深色主题
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.L04,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.appBarTitle.copyWith(
          color: AppColors.darkTextPrimary,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.darkSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.L04, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge
            .copyWith(color: AppColors.darkTextPrimary),
        displayMedium: AppTextStyles.displayMedium
            .copyWith(color: AppColors.darkTextPrimary),
        displaySmall: AppTextStyles.displaySmall
            .copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: AppTextStyles.headlineLarge
            .copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: AppTextStyles.headlineMedium
            .copyWith(color: AppColors.darkTextPrimary),
        headlineSmall: AppTextStyles.headlineSmall
            .copyWith(color: AppColors.darkTextPrimary),
        titleLarge:
            AppTextStyles.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: AppTextStyles.titleMedium
            .copyWith(color: AppColors.darkTextPrimary),
        titleSmall:
            AppTextStyles.titleSmall.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge:
            AppTextStyles.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        bodySmall: AppTextStyles.bodySmall
            .copyWith(color: AppColors.darkTextSecondary),
        labelLarge:
            AppTextStyles.labelLarge.copyWith(color: AppColors.darkTextPrimary),
        labelMedium: AppTextStyles.labelMedium
            .copyWith(color: AppColors.darkTextSecondary),
        labelSmall: AppTextStyles.labelSmall
            .copyWith(color: AppColors.darkTextSecondary),
      ),
    );
  }
}
