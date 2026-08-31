import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/storage_keys.dart';
import '../storage/shared_preferences_provider.dart';

part 'theme_mode_notifier.g.dart';

/// 主题管理Notifier - 只支持亮色/暗色模式
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  SharedPreferences? _prefs;

  @override
  Future<ThemeMode> build() async {
    _prefs = await ref.watch(sharedPreferencesProvider.future);
    return _loadThemeMode();
  }

  /// 从本地加载主题模式
  Future<ThemeMode> _loadThemeMode() async {
    final themeModeIndex = _prefs?.getInt(StorageKeys.themeMode);

    if (themeModeIndex != null) {
      return ThemeMode.values[themeModeIndex];
    }

    // 默认跟随系统
    return ThemeMode.system;
  }

  /// 保存主题模式到本地
  Future<void> _saveThemeMode(ThemeMode mode) async {
    await _prefs?.setInt(StorageKeys.themeMode, mode.index);
  }

  /// 切换主题模式（浅色/深色/跟随系统）
  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    await _saveThemeMode(mode);
  }

  /// 切换到浅色模式
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);

  /// 切换到深色模式
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// 跟随系统
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);

  /// 切换深色/浅色模式（用于快速切换）
  Future<void> toggleThemeMode() async {
    final currentMode = await future;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}
