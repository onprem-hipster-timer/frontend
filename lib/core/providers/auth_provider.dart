// 인증 상태 관리 프로바이더 (Ory Kratos)
//
// - 세션: Kratos 세션 토큰. SharedPreferences에 둔다(웹은 localStorage). 상태에는 넣지 않는다.
// - 백엔드 인증: 세션 토큰으로 받은 JWT(유효 10분). 상태에는 이 JWT와 사용자만 둔다.
// - JWT 갱신: 타이머 없이, 요청 직전에 만료가 가까운지 보고 다시 받는다(freshAccessToken).
//   백그라운드 탭에서는 타이머가 멈추므로 타이머 방식은 쓰지 않는다.
// - Kratos 호출은 KratosClient를 거쳐 이 파일에서만 한다.

import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/auth/kratos_client.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

/// 세션 토큰을 보관하는 SharedPreferences 키.
///
/// 웹에서는 localStorage의 `flutter.momeet.session_token`이 되며,
/// web/index.html이 Flutter 부팅 전에 첫 화면(랜딩 여부)을 정할 때 읽는다.
const sessionTokenKey = 'momeet.session_token';

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

// ============================================================
// 인증 상태 프로바이더
// ============================================================

/// 인증 상태를 관리하는 Notifier
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  Future<String?>? _refreshing;

  /// 복구 코드가 맞았을 때 받은 세션. 새 비밀번호를 저장할 때까지 메모리에만 둔다.
  String? _recoverySessionToken;

  KratosClient get _kratos => ref.read(kratosClientProvider);
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  String? get _sessionToken => _prefs.getString(sessionTokenKey);

  @override
  AuthStatus build() {
    final sessionToken = _sessionToken;
    if (sessionToken == null) return const AuthStatus.unauthenticated();

    Future.microtask(() => _restore(sessionToken));
    return const AuthStatus.loading();
  }

  /// 앱 시작 시 저장된 세션을 복원한다. 네트워크 오류면 세션 토큰은 남겨 두고 다음 실행에서 다시 시도한다.
  Future<void> _restore(String sessionToken) async {
    try {
      await _authenticateWith(sessionToken);
    } catch (e) {
      state = AuthStatus.error(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 세션 토큰으로 JWT를 받아 인증 상태가 된다. 세션이 끝났으면 토큰을 지우고 미인증이 된다.
  Future<String?> _authenticateWith(String sessionToken) async {
    final session = await _kratos.whoami(sessionToken);
    if (session == null) {
      await _prefs.remove(sessionTokenKey);
      state = const AuthStatus.unauthenticated();
      return null;
    }
    await _prefs.setString(sessionTokenKey, sessionToken);
    state = AuthStatus.authenticated(
      user: session.user,
      accessToken: session.accessToken,
    );
    return session.accessToken;
  }

  /// 백엔드 요청에 쓸 JWT. 만료까지 1분이 안 남았으면 새로 받는다. 미인증이면 null.
  Future<String?> freshAccessToken() async {
    final current = state;
    if (current is! AuthAuthenticated) return null;
    if (!_expiresWithin(current.accessToken, const Duration(minutes: 1))) {
      return current.accessToken;
    }
    return refreshAccessToken();
  }

  /// JWT를 새로 받는다. 동시에 여러 번 불려도 요청은 한 번만 보낸다.
  ///
  /// 세션이 끝났으면 미인증이 되고 null을 돌려준다. 네트워크 오류는 그대로 던진다.
  Future<String?> refreshAccessToken() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<String?> _refresh() async {
    final sessionToken = _sessionToken;
    if (sessionToken == null) {
      state = const AuthStatus.unauthenticated();
      return null;
    }
    return _authenticateWith(sessionToken);
  }

  /// JWT의 exp가 [margin] 안에 닥치는지 본다. 읽을 수 없는 토큰은 만료된 것으로 본다.
  static bool _expiresWithin(String jwt, Duration margin) {
    try {
      final payload = base64Url.normalize(jwt.split('.')[1]);
      final claims = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map;
      final exp = DateTime.fromMillisecondsSinceEpoch(
        (claims['exp'] as num).toInt() * 1000,
      );
      return exp.isBefore(DateTime.now().add(margin));
    } catch (_) {
      return true;
    }
  }

  /// 이메일/비밀번호로 로그인
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final flow = await _kratos.createFlow(KratosFlowType.login);
      final result = await _kratos.submit(KratosFlowType.login, flow.id, {
        'method': 'password',
        'identifier': email,
        'password': password,
      });
      await _authenticateWith(result.sessionToken!);
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 회원가입. 이메일 인증 플로우 ID를 돌려준다.
  ///
  /// 세션 토큰은 저장하지만 상태는 바꾸지 않는다. 바로 인증 상태가 되면 라우터가
  /// 가입 화면에서 홈으로 보내 버리므로, 인증 화면을 거친 뒤 [completeSignUp]으로 바꾼다.
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final flow = await _kratos.createFlow(KratosFlowType.registration);
      final result = await _kratos.submit(
        KratosFlowType.registration,
        flow.id,
        {
          'method': 'password',
          'traits': {'email': email},
          'password': password,
        },
      );
      await _prefs.setString(sessionTokenKey, result.sessionToken!);
      return result.verificationFlowId;
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 가입 때 저장한 세션으로 로그인 상태가 된다.
  Future<void> completeSignUp() async {
    try {
      final sessionToken = _sessionToken;
      if (sessionToken != null) await _authenticateWith(sessionToken);
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 이메일 인증 코드를 보낸다. 새 인증 플로우를 만들어 그 ID를 돌려준다.
  Future<String> sendVerificationCode(String email) async {
    try {
      final flow = await _kratos.createFlow(KratosFlowType.verification);
      await _kratos.submit(KratosFlowType.verification, flow.id, {
        'method': 'code',
        'email': email,
      });
      return flow.id;
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 이메일 인증 코드를 확인한다.
  ///
  /// 저장된 세션이 있으면 인증 결과(email_verified)가 담긴 JWT로 로그인 상태가 된다.
  Future<void> verifyEmail({
    required String flowId,
    required String code,
  }) async {
    try {
      await _kratos.submit(KratosFlowType.verification, flowId, {
        'method': 'code',
        'code': code,
      });
      final sessionToken = _sessionToken;
      if (sessionToken != null) await _authenticateWith(sessionToken);
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 로그아웃. 서버 세션을 끝내지 못하면 로그인 상태를 유지하고 예외를 던진다.
  Future<void> signOut() async {
    try {
      final sessionToken = _sessionToken;
      if (sessionToken != null) await _kratos.logout(sessionToken);
      await _prefs.remove(sessionTokenKey);
      state = const AuthStatus.unauthenticated();
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 비밀번호 복구 코드를 이메일로 보낸다. 복구 플로우 ID를 돌려준다.
  Future<String> sendRecoveryCode(String email) async {
    try {
      final flow = await _kratos.createFlow(KratosFlowType.recovery);
      await _kratos.submit(KratosFlowType.recovery, flow.id, {
        'method': 'code',
        'email': email,
      });
      return flow.id;
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 복구 코드를 확인한다. 새 비밀번호를 설정할 settings 플로우 ID를 돌려준다.
  ///
  /// 복구가 만든 세션은 저장하지 않는다. 코드만 확인하고 떠나면 비밀번호를 바꾸지 않은 채
  /// 로그인 상태가 되기 때문이다.
  Future<String> verifyRecoveryCode({
    required String flowId,
    required String code,
  }) async {
    try {
      final result = await _kratos.submit(KratosFlowType.recovery, flowId, {
        'method': 'code',
        'code': code,
      });
      _recoverySessionToken = result.recoverySessionToken!;
      return result.settingsFlowId!;
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 복구 세션으로 새 비밀번호를 저장하고 로그인 상태가 된다.
  Future<void> completeRecovery({
    required String settingsFlowId,
    required String newPassword,
  }) async {
    try {
      final sessionToken = _recoverySessionToken!;
      await _kratos.submit(KratosFlowType.settings, settingsFlowId, {
        'method': 'password',
        'password': newPassword,
      }, sessionToken: sessionToken);
      _recoverySessionToken = null;
      await _authenticateWith(sessionToken);
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 현재 비밀번호로 다시 인증한 뒤 새 비밀번호로 바꾼다.
  ///
  /// Kratos는 최근(privileged_session_max_age, 15분) 인증한 세션만 설정을 바꾸게 하므로
  /// 항상 재인증부터 한다.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final current = state;
      final sessionToken = _sessionToken;
      if (current is! AuthAuthenticated || sessionToken == null) {
        throw StateError('로그인 상태가 아닙니다');
      }
      final refresh = await _kratos.createFlow(
        KratosFlowType.login,
        sessionToken: sessionToken,
        refresh: true,
      );
      await _kratos.submit(KratosFlowType.login, refresh.id, {
        'method': 'password',
        'identifier': current.user.email,
        'password': currentPassword,
      }, sessionToken: sessionToken);
      final settings = await _kratos.createFlow(
        KratosFlowType.settings,
        sessionToken: sessionToken,
      );
      await _kratos.submit(KratosFlowType.settings, settings.id, {
        'method': 'password',
        'password': newPassword,
      }, sessionToken: sessionToken);
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }
}

// ============================================================
// 헬퍼 프로바이더
// ============================================================

/// 현재 로그인 중인 사용자
@riverpod
AuthUser? currentUser(Ref ref) {
  return ref
      .watch(authProvider)
      .whenOrNull(authenticated: (user, accessToken) => user);
}

/// 현재 백엔드용 JWT
@riverpod
String? accessToken(Ref ref) {
  return ref
      .watch(authProvider)
      .whenOrNull(authenticated: (user, accessToken) => accessToken);
}

/// 인증 여부 확인
@riverpod
bool isAuthenticated(Ref ref) {
  return ref
      .watch(authProvider)
      .maybeWhen(
        authenticated: (user, accessToken) => true,
        orElse: () => false,
      );
}

/// 인증 로딩 여부 확인
@riverpod
bool isAuthLoading(Ref ref) {
  return ref
      .watch(authProvider)
      .maybeWhen(loading: () => true, orElse: () => false);
}
