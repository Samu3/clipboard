import 'package:shared_preferences/shared_preferences.dart';

/// API 配置 - 单例模式
class ApiConfig {
  ApiConfig._();

  static final ApiConfig _instance = ApiConfig._();
  factory ApiConfig() => _instance;

  /// 开发环境
  static const String devBaseUrl = 'http://nat.lefuenergy.com:10081/unique-app';

  /// 生产环境
  static const String prodBaseUrl =
      'https://uniquehealth.lefuenergy.com/unique-app';

  /// 当前使用的域名
  String _domain = '';

  /// 获取当前 BaseUrl
  String get baseUrl {
    if (_domain.isNotEmpty) {
      return _domain;
    }
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? prodBaseUrl : prodBaseUrl;
  }

  /// 从 SharedPreferences 初始化
  Future<void> init(SharedPreferences prefs) async {
    final savedDomain = prefs.getString("APPDOMAIN");
    if (savedDomain != null && savedDomain.isNotEmpty) {
      _domain = savedDomain;
    } else {}
  }

  /// 更新自定义域名
  Future<void> updateDomain(String domain, SharedPreferences prefs) async {
    if (domain.isNotEmpty) {
      _domain = domain;
      await prefs.setString("APPDOMAIN", domain);
    } else {
      _domain = '';
      await prefs.remove("APPDOMAIN");
    }
  }

  static const String app_type = "PasteLink";
}
