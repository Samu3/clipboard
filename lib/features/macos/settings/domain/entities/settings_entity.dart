import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_entity.freezed.dart';

@freezed
class SettingsEntity with _$SettingsEntity {
  const factory SettingsEntity({
    // 快捷键设置
    @Default('Command+Shift+V') String hotKey,
    @Default(0x37) int modifierKeyCode,  // Command 键码
    @Default(0x09) int mainKeyCode,       // V 键码

    // 常规设置
    @Default(false) bool autoStart,
    @Default(true) bool soundEnabled,

    // 其他设置
    @Default(30) int historyLimit,
  }) = _SettingsEntity;
}
