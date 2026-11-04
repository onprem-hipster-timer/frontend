// 인증 상태 관리 프로바이더 (Ory Kratos)
//
// - 세션: Kratos 세션 토큰. SharedPreferences에 둔다(웹은 localStorage). 상태에는 넣지 않는다.
// - 백엔드 인증: 세션 토큰으로 받은 JWT(유효 10분). 상태에는 이 JWT와 사용자만 둔다.
// - JWT 갱신: 타이머 없이, 요청 직전에 만료가 가까운지 보고 다시 받는다(freshAccessToken).
//   백그라운드 탭에서는 타이머가 멈추므로 타이머 방식은 쓰지 않는다.
// - Kratos 호출은 KratosClient를 거쳐 이 파일에서만 한다.

import 'dart:async';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' show JWT;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/auth/kratos_client.dart';
import 'package:momeet/core/auth/kratos_models.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/shared_preferences_provider.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

/// 세션 토큰을 보관하는 SharedPreferences 키.
///
/// 웹에서는 localStorage의 `flutter.momeet.session_token`이 되며,
/// web/index.html이 Flutter 부팅 전에 첫 화면(랜딩 여부)을 정할 때 읽는다.
const sessionTokenKey = 'momeet.session_token';

/// Google 로그인을 시작할 때 받은 교환 코드를 보관하는 키.
///
/// Google을 다녀오는 동안 페이지가 새로 뜨므로 메모리가 아니라 저장소에 둔다.
/// 이 값이 있어야 돌아온 코드로 세션을 받을 수 있으므로, 남이 보낸 복귀 링크로는 로그인되지 않는다.
const googleSignInCodeKey = 'momeet.google_sign_in_code';

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

  /// 로그아웃 횟수. whoami를 기다리는 사이 로그아웃했는지 알아내는 데 쓴다.
  int _signOuts = 0;

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
    final signOutsBefore = _signOuts;
    final session = await _kratos.whoami(sessionToken);
    // 기다리는 사이 로그아웃했으면 끝난 세션을 되살리지 않는다
    if (_signOuts != signOutsBefore) return null;
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
  ///
  /// 서명은 검증하지 않는다. 앱은 갱신 시점만 정하고, 서명 검증은 backend가 한다.
  static bool _expiresWithin(String jwt, Duration margin) {
    final payload = JWT.tryDecode(jwt)?.payload;
    final exp = payload is Map ? payload['exp'] : null;
    if (exp is! num) return true;
    return DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
    ).isBefore(DateTime.now().add(margin));
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
      final type = AuthErrorType.classify(e);
      if (type == AuthErrorType.emailNotVerified) {
        throw EmailNotVerifiedException(
          message: type.localized,
          originalError: e,
          verificationFlowId: e is KratosException
              ? e.verificationFlowId
              : null,
        );
      }
      throw AuthException(message: type.localized, originalError: e);
    }
  }

  /// 이 브라우저에서 시작한 Google 로그인이 돌아오기를 기다리는 중인지
  bool get hasPendingGoogleSignIn =>
      _prefs.getString(googleSignInCodeKey) != null;

  /// Google 로그인을 시작한다. 브라우저를 보낼 Google 주소를 돌려준다.
  ///
  /// 로그인을 마치면 Kratos가 브라우저를 [returnTo]에 `code`를 붙여 돌려보낸다.
  /// [signUp]이면 가입 플로우로 시작한다.
  Future<Uri> startGoogleSignIn({
    required Uri returnTo,
    bool signUp = false,
  }) async {
    try {
      final type = signUp ? KratosFlowType.registration : KratosFlowType.login;
      final flow = await _kratos.createFlow(
        type,
        returnTo: returnTo.toString(),
      );
      await _prefs.setString(
        googleSignInCodeKey,
        flow.sessionTokenExchangeCode!,
      );
      return await _kratos.submitOidc(type, flow.id, 'google');
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// Google에서 돌아온 `code`로 세션을 받아 로그인한다. 교환 코드는 성공·실패와 상관없이 한 번만 쓴다.
  Future<void> completeGoogleSignIn(String code) async {
    try {
      final initCode = _prefs.getString(googleSignInCodeKey);
      await _prefs.remove(googleSignInCodeKey);
      if (initCode == null) {
        throw StateError('이 브라우저에서 시작한 Google 로그인이 아닙니다');
      }
      final sessionToken = await _kratos.exchangeSessionToken(
        initCode: initCode,
        returnToCode: code,
      );
      await _authenticateWith(sessionToken);
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 회원가입. 이메일 인증 플로우 ID를 돌려준다.
  ///
  /// 이메일 인증 전에는 세션이 없다(Kratos가 가입 직후 세션을 주지 않음). 인증을 마친 뒤 로그인한다.
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
      return result.verificationFlowId;
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
      _signOuts++;
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

/// Google 로그인을 쓸 수 있는지. 서버(Kratos)가 켰을 때만 true다.
///
/// 웹에서만 쓴다. Kratos가 로그인 뒤 돌려보내는 주소(allowed_return_urls)가 웹 앱 주소뿐이다.
/// 서버가 켠 제공자는 로그인 플로우의 oidc 버튼으로 알 수 있다. 앱 실행 중 한 번만 묻는다.
@Riverpod(keepAlive: true)
Future<bool> googleSignInAvailable(Ref ref) async {
  if (!ref.read(isWebProvider)) return false;
  try {
    final flow = await ref
        .read(kratosClientProvider)
        .createFlow(KratosFlowType.login);
    return flow.oidcProviders.contains('google');
  } catch (_) {
    return false;
  }
}

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
