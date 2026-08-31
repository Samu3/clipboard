import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required String email,
    required String accountId,
    required String uid,
    required String token,
    required String accessToken,
    required String emailVerify,
    required String phoneNum,
    required int status,
    required int lunchType,
  }) = _AuthState;

  const AuthState._();

  /// 是否已认证
  bool get isAuthenticated => accountId.isNotEmpty && uid.isNotEmpty;
}
