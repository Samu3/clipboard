import 'package:clipboard/features/macos/settings/domain/entities/settings_entity.dart';
import 'package:clipboard/features/macos/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences prefs;

  SettingsRepositoryImpl(this.prefs);

  static const String _keyHotKey = 'settings_hot_key';
  static const String _keyModifierKeyCode = 'settings_modifier_key_code';
  static const String _keyMainKeyCode = 'settings_main_key_code';
  static const String _keyAutoStart = 'settings_auto_start';
  static const String _keySoundEnabled = 'settings_sound_enabled';
  static const String _keyHistoryLimit = 'settings_history_limit';

  @override
  Future<SettingsEntity> getSettings() async {
    // 默认快捷键：Command+Shift+V
    // Command: 1 << 8 = 256 (0x100)
    // Shift: 1 << 9 = 512 (0x200)
    // 组合: 256 + 512 = 768 (0x300)
    // V 键: 0x09
    const int defaultModifiers = 768; // Command + Shift
    const int defaultKeyCode = 0x09; // V 键

    return SettingsEntity(
      hotKey: prefs.getString(_keyHotKey) ?? 'Command+Shift+V',
      modifierKeyCode: prefs.getInt(_keyModifierKeyCode) ?? defaultModifiers,
      mainKeyCode: prefs.getInt(_keyMainKeyCode) ?? defaultKeyCode,
      autoStart: prefs.getBool(_keyAutoStart) ?? false,
      soundEnabled: prefs.getBool(_keySoundEnabled) ?? true,
      historyLimit: prefs.getInt(_keyHistoryLimit) ?? 30,
    );
  }

  @override
  Future<void> saveSettings(SettingsEntity settings) async {
    await prefs.setString(_keyHotKey, settings.hotKey);
    await prefs.setInt(_keyModifierKeyCode, settings.modifierKeyCode);
    await prefs.setInt(_keyMainKeyCode, settings.mainKeyCode);
    await prefs.setBool(_keyAutoStart, settings.autoStart);
    await prefs.setBool(_keySoundEnabled, settings.soundEnabled);
    await prefs.setInt(_keyHistoryLimit, settings.historyLimit);
  }

  @override
  Future<void> updateHotKey(String hotKey, int modifierKeyCode, int mainKeyCode) async {
    await prefs.setString(_keyHotKey, hotKey);
    await prefs.setInt(_keyModifierKeyCode, modifierKeyCode);
    await prefs.setInt(_keyMainKeyCode, mainKeyCode);
  }

  @override
  Future<void> updateAutoStart(bool enabled) async {
    await prefs.setBool(_keyAutoStart, enabled);
  }

  @override
  Future<void> updateSoundEnabled(bool enabled) async {
    await prefs.setBool(_keySoundEnabled, enabled);
  }
}
