import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unique_health/core/auth/auth_provider.dart';
import 'package:unique_health/core/locale/providers/locale_provider.dart';
import 'package:unique_health/core/network/api_config.dart';
import 'package:unique_health/core/utils/logger.dart';
import 'channel_names.dart';

/// App Channel - 通用原生功能
class AppChannel {
  AppChannel._internal() {
    _initMethodChannel();
  }

  factory AppChannel() => _instance;

  static final AppChannel _instance = AppChannel._internal();

  static const MethodChannel appChannel =
      MethodChannel(ChannelNames.appChannel);

  static const MethodChannel hybridChannel =
      MethodChannel(ChannelNames.hybridChannel);

  /// WidgetRef 用于访问 Riverpod providers
  WidgetRef? _ref;

  /// 设置 WidgetRef
  void setRef(WidgetRef ref) {
    _ref = ref;
  }

  void closeFlutterVC() {
    AppChannel.hybridChannel.invokeListMethod("closeFlutterVc");
  }

  Future<Map<String, dynamic>> getAppAuth() async {
    try {
      final result =
          await AppChannel.appChannel.invokeMapMethod<String, dynamic>(
        "flutterGetAppAuth",
      );
      return result ?? {};
    } on PlatformException catch (e) {
      throw ChannelException('getAppAuth failed: ${e.message}');
    }
  }

  _initMethodChannel() {
    appChannel.setMethodCallHandler((call) async {
      logger.methodChannel("method:${call.method} arguments:${call.arguments}");
      switch (call.method) {
        case "nativeSendAppAuth":
          final raw = call.arguments as Map?;
          final Map<String, dynamic>? map =
              raw != null ? Map<String, dynamic>.from(raw) : null;

          if (map != null && map.isNotEmpty) {
            logger.methodChannel(
                '🔐 onAuthUpdated callback triggered with: $map');

            var auth = await _ref?.read(authStateNotifierProvider.notifier);

            auth?.updateAuthFromMap(map);
          }

          return {'success': true};

        case "nativeSendAppDomain":
          final raw = call.arguments as Map?;
          final Map<String, dynamic>? map =
              raw != null ? Map<String, dynamic>.from(raw) : null;

          if (map != null && map.isNotEmpty) {
            final url = map["AppDomain"] as String?;
            logger.methodChannel('🌐 Domain update received: $url');
            if (url != null && _ref != null) {
              // 获取 SharedPreferences
              final prefs = _ref!.read(sharedPreferencesProvider);

              // 更新 ApiConfig 单例
              await ApiConfig().updateDomain(url, prefs);
            }
          }

          return {'success': true};

        case "nativeSendCurrentLanguage":
          final raw = call.arguments as Map?;
          final Map<String, dynamic>? map =
              raw != null ? Map<String, dynamic>.from(raw) : null;

          if (map != null && map.isNotEmpty) {
            final newLang = map["currentLanguage"] as String?;
            logger.methodChannel('🌍 Native language update: $newLang');
            if (newLang != null && newLang.isNotEmpty && _ref != null) {
              try {
                await _ref!
                    .read(currentLanguageProvider.notifier)
                    .changeLanguage(newLang);
                logger.methodChannel('🌍 Language change completed');
              } catch (e) {
                logger.methodChannel(
                    '🌍 Language change failed (app may be disposing): $e');
                // 静默失败，可能是 FlutterViewController 正在销毁
              }
            }
          }
          break;
        default:
          logger.methodChannel('📱 Unknown method: ${call.method}');
      }
    });
  }
}

/// Channel异常
class ChannelException implements Exception {
  final String message;

  const ChannelException(this.message);

  @override
  String toString() => 'ChannelException: $message';
}
