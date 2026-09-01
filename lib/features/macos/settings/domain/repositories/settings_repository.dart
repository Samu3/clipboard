import 'package:clipboard/features/macos/settings/domain/entities/settings_entity.dart';

abstract class SettingsRepository {
  /// 获取设置
  Future<SettingsEntity> getSettings();

  /// 保存设置
  Future<void> saveSettings(SettingsEntity settings);

  /// 更新快捷键
  Future<void> updateHotKey(String hotKey, int modifierKeyCode, int mainKeyCode);

  /// 更新开机自启动
  Future<void> updateAutoStart(bool enabled);

  /// 更新声音提示
  Future<void> updateSoundEnabled(bool enabled);
}
