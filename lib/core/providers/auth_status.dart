import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/core/auth/auth_user.dart';

part 'auth_status.freezed.dart';

// ============================================================
// 상태 모델
// ============================================================

/// 인증 상태
@freezed
sealed class AuthStatus with _$AuthStatus {
  /// 저장된 세션을 확인하는 중 (앱 시작 시에만)
  const factory AuthStatus.loading() = AuthLoading;

  /// 인증됨. [accessToken]은 백엔드에 보낼 JWT다.
  const factory AuthStatus.authenticated({
    required AuthUser user,
    required String accessToken,
  }) = AuthAuthenticated;

  /// 미인증
  const factory AuthStatus.unauthenticated() = AuthUnauthenticated;

  /// 앱 시작 시 세션을 확인하지 못함 (네트워크 오류 등)
  const factory AuthStatus.error({
    required String message,
    dynamic originalError,
  }) = AuthStatusError;
}
