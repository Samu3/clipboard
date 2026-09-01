import 'package:clipboard/features/macos/settings/channel/native_setting_channel.dart';
import 'package:clipboard/features/macos/settings/data/providers/settings_providers.dart';
import 'package:clipboard/features/macos/settings/domain/entities/settings_entity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/services.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<SettingsEntity> build() async {
    final repository = ref.watch(settingsRepositoryProvider);
    return await repository.getSettings();
  }

  Future<void> startHotKey() async {
    var channel = ref.read(nativeSettingProvider);
    await channel.startHotKey();
  }

  /// 更新快捷键
  Future<void> updateHotKey(
      String hotKey, int modifierKeyCode, int mainKeyCode) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateHotKey(hotKey, modifierKeyCode, mainKeyCode);
    var channel = ref.read(nativeSettingProvider);
    await channel.updateHotKey(hotKey, modifierKeyCode, mainKeyCode);

    // 刷新状态
    ref.invalidateSelf();
  }

  Future<void> stopHotKey() async {
    var channel = ref.read(nativeSettingProvider);
    await channel.stopHotKey();
  }

  /// 更新开机自启动
  Future<void> updateAutoStart(bool enabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateAutoStart(enabled);

    // 调用原生方法设置开机自启动
    try {
      var channel = ref.read(nativeSettingProvider);
      await channel.updateAutoStart(enabled);
    } catch (e) {
      print('设置开机自启动失败: $e');
    }

    ref.invalidateSelf();
  }

  /// 更新声音提示
  Future<void> updateSoundEnabled(bool enabled) async {
    final repository = ref.read(settingsRepositoryProvider);
    await repository.updateSoundEnabled(enabled);
    ref.invalidateSelf();
  }
}
