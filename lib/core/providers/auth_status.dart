import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/auth/guest_user.dart';

part 'auth_status.freezed.dart';

// ============================================================
// 상태 모델
// ============================================================

/// 게스트 요청이 거절된 까닭
enum GuestDenial {
  /// 약관이 바뀌어 다시 동의해야 한다(428). 동의를 남기면 지운다
  consentRequired,

  /// 세션은 남았지만 모임이 지금 게스트를 받지 않는다(403. 게스트 허용이나 공개를 껐거나 기간이 끝났다)
  notAcceptingGuests,
}

/// 미인증이 된 까닭
enum AuthEndReason {
  /// 거절된 게스트의 세션을 확인해 보니 끝났다(주인이 뺐거나 게스트 기간이 끝나 게스트가 지워졌다)
  guestRemoved,
}

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

  /// 게스트 세션. [accessToken]은 [guest]의 모임 경로에 보낼 JWT다. 회원 화면과 회원 요청에는 쓰지 않는다.
  ///
  /// [denial]은 게스트 요청이 거절된 까닭이다(요청 파이프라인이 정한다). 모임 화면이 그 까닭의 화면을 보인다.
  const factory AuthStatus.guest({
    required GuestUser guest,
    required String accessToken,
    GuestDenial? denial,
  }) = AuthGuest;

  /// 미인증. [reason]은 로그인 상태가 끝난 까닭이 따로 있을 때다
  const factory AuthStatus.unauthenticated({AuthEndReason? reason}) =
      AuthUnauthenticated;

  /// 앱 시작 시 세션을 확인하지 못함 (네트워크 오류 등)
  const factory AuthStatus.error({
    required String message,
    dynamic originalError,
  }) = AuthStatusError;
}
