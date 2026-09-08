import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clipboard/core/auth/auth_provider.dart';
import '../../storage/storage_keys.dart';

/// 认证拦截器
/// 自动在请求头中添加Token和公共Headers
class AuthInterceptor extends Interceptor {
  final Ref ref;
  final Dio dio;

  // 是否正在刷新token 【锁】
  bool _isRefreshing = false;
  // 等待队列：刷新成功后放行阻塞请求
  final List<Completer<void>> _pendingRequests = [];

  AuthInterceptor(this.ref, this.dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // 从本地存储获取Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.authToken);
      final accountId = prefs.getString(StorageKeys.userId);

      // 添加 Access-Token
      if (token != null && token.isNotEmpty) {
        options.headers['Access-Token'] = token;
      }

      // 添加 accountId
      if (accountId != null && accountId.isNotEmpty) {
        options.headers['accountId'] = accountId;
      }

      // 动态更新时间戳和 traceId
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      options.headers['Timestamp'] = timestamp;
      options.headers['tlogTraceId'] = 'F$timestamp';

      // 确保公共Headers存在（防止被覆盖）
      options.headers.putIfAbsent('Content-Type', () => 'application/json');
      options.headers.putIfAbsent('Accept-Language', () => 'zh');
      options.headers.putIfAbsent(
          'User-Agent', () => 'com.lefu.uniquehealth/1.0.0 (iPhone; iOS 18.0)');
      options.headers.putIfAbsent('App-Type', () => 'ClipSync');
      options.headers.putIfAbsent('App-Version', () => '1.0.0');
      options.headers.putIfAbsent('appName', () => 'ClipSync');
      options.headers.putIfAbsent('Timezone', () => 'Asia/Shanghai');
      options.headers.putIfAbsent('Local', () => 'CN');

      handler.next(options);
    } catch (e) {
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 可以在这里处理全局响应
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;

    // 处理401未授权错误
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        final completer = Completer<void>();
        _pendingRequests.add(completer);
        try {
          await completer.future;
          // token刷新完毕，重试当前请求
          final res = await _retryRequest(err.requestOptions);
          return handler.resolve(res);
        } catch (e) {
          return handler.next(err);
        }
      }

      // ======= 场景2：当前没有刷新，开始执行刷新逻辑 =======
      _isRefreshing = true;
      try {
        final authState = await ref.watch(authStateNotifierProvider.future);

        // 【1.调用刷新Token接口】
        final refreshResp = await dio.get("/app/user/refreshToken",
            options: Options(headers: err.requestOptions.headers),
            queryParameters: {"refreshToken": authState.token});

        final newAccessToken = refreshResp.data["accessToken"];
        final newRefreshToken = refreshResp.data["token"];

        final noti = await ref.read(authStateNotifierProvider.notifier);

        noti.updateUser(token: newRefreshToken, accessToken: newAccessToken);
        // 持久化保存新token（Hive/SharedPreferences）
        // await _saveToken(newAccessToken, newRefreshToken);

        // 【2.放行队列里所有等待的请求】
        for (var completer in _pendingRequests) {
          completer.complete();
        }
        _pendingRequests.clear();

        // 【3.重试当前401失败的请求】
        final retryResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (refreshError) {
        // ❗刷新token失败：全部队列失败、跳登录页
        for (var completer in _pendingRequests) {
          completer.completeError(refreshError);
        }
        _pendingRequests.clear();
        // 跳转登录，清除本地登录信息
        // await _clearToken();
        // navigator 跳转登录页面

        return handler.next(err);
      } finally {
        // 解锁
        _isRefreshing = false;
      }
    }

    handler.next(err);
  }

  /// 使用新token重试请求
  Future<Response> _retryRequest(RequestOptions options) async {
    // 读取最新accessToken
    // final token = await _getAccessToken();
    // options.headers["Authorization"] = "Bearer $token";
    return await dio.fetch(options);
  }
}
