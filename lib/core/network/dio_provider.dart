import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'api_config.dart';

part 'dio_provider.g.dart';

/// Dio 实例配置
@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig().baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: _getCommonHeaders(),
    ),
  );

  // 添加认证拦截器
  dio.interceptors.add(AuthInterceptor(ref, dio));

  // 添加日志拦截器（仅在开发模式）
  dio.interceptors.add(LoggingInterceptor());

  // 清理资源
  ref.onDispose(() => dio.close());

  return dio;
}

/// 获取公共请求头
Map<String, dynamic> _getCommonHeaders() {
  return {
    'Content-Type': 'application/json',
    'Accept-Language': 'zh', // 默认中文，拦截器中会动态更新
    'User-Agent': 'com.lefu.uniquehealth/1.0.0 (iPhone; iOS 18.0)',
    'App-Type': 'PasteLink',
    'App-Version': '1.0.0', // TODO: 从 package_info 获取
    'appName': 'PasteLink',
    'Timezone': 'Asia/Shanghai',
    'Local': 'CN',
    'Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    'tlogTraceId': 'F${DateTime.now().millisecondsSinceEpoch}',
  };
}
