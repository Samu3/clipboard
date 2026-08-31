import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:clipboard/core/auth/auth_state.dart';
import 'package:clipboard/core/channel/native_channel.dart';
import 'package:clipboard/core/utils/logger.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<AuthState> build() async {
    // 注册原生认证信息更新回调

    // 初始化默认状态
    return state.value ??
        AuthState(
          email: "",
          accountId: "default_account",
          uid: "default_user",
          token: "",
          accessToken: "",
          emailVerify: "",
          phoneNum: "",
          status: 0,
          lunchType: 0,
        );
  }

  Future<void> getAuthState() async {
    logger.methodChannel('🔐 Calling getAppAuth');
    final map = await AppChannel().getAppAuth();
    logger.methodChannel('🔐 getAppAuth result: $map');
    if (map.isNotEmpty) {
      updateAuthFromMap(map);
    }
  }

  /// 从 map 更新认证状态（内部方法）
  void updateAuthFromMap(Map<String, dynamic> map) {
    logger.methodChannel('🔐 Updating auth state from map: $map');
    state = AsyncValue.data(AuthState(
      email: map['email'] as String? ?? '',
      accountId: map['accountId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      token: map['token'] as String? ?? '',
      accessToken: map['accessToken'] as String? ?? '',
      emailVerify: map['emailVerify'] as String? ?? '',
      phoneNum: map['phoneNum'] as String? ?? '',
      status: map['status'] as int? ?? 0,
      lunchType: map['lunchType'] as int? ?? 0,
    ));
    logger.methodChannel('🔐 Auth state updated successfully');
    // water_provider 会自动通过 ref.watch 监听变化并重建
  }

  /// 更新认证状态
  void updateAuthState(AuthState newState) {
    state = AsyncValue.data(newState);
    logger.methodChannel('🔐 Auth state updated');
  }

  /// 更新用户信息
  void updateUser({
    String? email,
    String? accountId,
    String? uid,
    String? token,
    String? accessToken,
    String? emailVerify,
    String? phoneNum,
    int? status,
    int? lunchType,
  }) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(
      email: email ?? current.email,
      accountId: accountId ?? current.accountId,
      uid: uid ?? current.uid,
      token: token ?? current.token,
      accessToken: accessToken ?? current.accessToken,
      emailVerify: emailVerify ?? current.emailVerify,
      phoneNum: phoneNum ?? current.phoneNum,
      status: status ?? current.status,
      lunchType: lunchType ?? current.lunchType,
    ));
    logger.methodChannel('🔐 User info updated');
  }

  /// 登出，清空状态
  void logout() {
    state = const AsyncValue.data(AuthState(
      email: "",
      accountId: "",
      uid: "",
      token: "",
      accessToken: "",
      emailVerify: "",
      phoneNum: "",
      status: 0,
      lunchType: 0,
    ));
    logger.methodChannel('🔐 Logged out');
  }
}
