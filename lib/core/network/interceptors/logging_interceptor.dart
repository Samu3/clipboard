import 'dart:convert';
import 'package:dio/dio.dart';
import '../../utils/logger.dart';

/// 日志拦截器
/// 记录所有HTTP请求和响应，并写入日志文件
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final uri = options.uri;
    final method = options.method;

    logger.http(
        '→ $method $uri Headers: ${options.headers} Body: ${options.data}',
        level: LogLevel.info);

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final url = response.requestOptions.uri.toString();
    final statusCode = response.statusCode;
    final method = response.requestOptions.method;

    // 排除特定接口的详细日志
    if (!url.contains("getIncrListByAppType")) {
      logger.http(
        '← $statusCode $method $url Response: ${jsonEncode(response.data)}',
        level: statusCode == 200 ? LogLevel.info : LogLevel.warning,
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final url = err.requestOptions.uri.toString();
    final method = err.requestOptions.method;

    logger.e(
      '✗ $method $url',
      category: LogCategory.http,
      error: '${err.type.name}: ${err.message}',
      stackTrace: err.stackTrace,
    );

    if (err.response != null) {
      logger.http(
        'Error Response: ${err.response?.data}',
        level: LogLevel.error,
      );
    }

    handler.next(err);
  }
}
