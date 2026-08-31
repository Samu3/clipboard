/// 本地存储Key常量
class StorageKeys {
  StorageKeys._();

  // 认证相关
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';

  // 用户信息
  static const String userInfo = 'user_info';
  static const String userAvatar = 'user_avatar';

  // 应用设置
  static const String themeMode = 'theme_mode';
  static const String themeColor = 'theme_color';
  static const String languageCode = 'language_code';
  static const String isFirstLaunch = 'is_first_launch';

  // 喝水相关
  static const String dailyWaterGoal = 'daily_water_goal';
  static const String waterUnit = 'water_unit';

  // 多语言相关
  static const String publicLangTimestamp = 'public_lang_timestamp';
  static const String privateLangTimestamp = 'private_lang_timestamp';
  static const String languageData = 'language_data';
}
