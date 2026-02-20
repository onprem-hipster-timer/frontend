// 인증 상태 관리 프로바이더 (Supabase)
//
// 이 파일은 다음을 관리합니다:
// - Supabase 인증 상태
// - JWT 토큰 관리
// - 사용자 세션
// - 로그인/로그아웃 로직

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

// ============================================================
// 상태 모델
// ============================================================

/// 인증 상태
///
/// Supabase의 AuthState(이벤트 모델)와 구분하기 위해 AuthStatus로 명명합니다.
@freezed
sealed class AuthStatus with _$AuthStatus {
  /// 인증 대기 중 (초기 로딩)
  const factory AuthStatus.loading() = AuthLoading;

  /// 인증됨 (로그인함)
  const factory AuthStatus.authenticated({
    required User user,
    required String accessToken,
    String? refreshToken,
  }) = AuthAuthenticated;

  /// 미인증 (로그인하지 않음)
  const factory AuthStatus.unauthenticated() = AuthUnauthenticated;

  /// 에러
  const factory AuthStatus.error({
    required String message,
    dynamic originalError,
  }) = AuthStatusError;
}

// ============================================================
// Supabase 클라이언트 프로바이더
// ============================================================

/// Supabase 클라이언트 인스턴스 제공자
///
/// ⚠️ 주의: main.dart에서 초기화되어야 합니다.
/// ```dart
/// await Supabase.initialize(
///   url: 'YOUR_SUPABASE_URL',
///   anonKey: 'YOUR_SUPABASE_ANON_KEY',
/// );
/// ```
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

// ============================================================
// 인증 상태 프로바이더
// ============================================================

/// 인증 상태를 관리하는 Notifier
///
/// 사용 예:
/// ```dart
/// final state = ref.watch(authProvider);
/// state.maybeWhen(
///   authenticated: (user, token, refreshToken) {
///     debugPrint('로그인됨: ${user.email}');
///   },
///   unauthenticated: () {
///     debugPrint('로그아웃됨');
///   },
///   loading: () => showLoader(),
///   error: (message, error) => showError(message),
///   orElse: () {},
/// );
/// ```
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthStatus build() {
    final supabase = ref.read(supabaseClientProvider);

    final subscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        final session = data.session;

        if (AppConfig.enableDebugLogging) {
          debugPrint(
              '🔀 [AUTH] ${data.event.name}, user: ${session?.user.email}');
        }

        switch (data.event) {
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.userUpdated:
            if (session != null) {
              state = AuthStatus.authenticated(
                user: session.user,
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
              );
            } else {
              state = const AuthStatus.unauthenticated();
            }
          case AuthChangeEvent.signedOut:
            state = const AuthStatus.unauthenticated();
          case AuthChangeEvent.passwordRecovery:
          case AuthChangeEvent.mfaChallengeVerified:
          // userDeleted: 백엔드에서 발행된 적 없는 구현 불가능 이벤트
          // https://github.com/supabase/supabase/issues/10309
          // ignore: deprecated_member_use
          case AuthChangeEvent.userDeleted:
            break;
        }
      },
      onError: (error) {
        if (AppConfig.enableDebugLogging) {
          debugPrint('❌ [AUTH] Stream error: $error');
        }
        state = const AuthStatus.unauthenticated();
      },
    );

    ref.onDispose(() => subscription.cancel());

    // currentSession은 Supabase.initialize() 완료 후 동기적으로 사용 가능
    final session = supabase.auth.currentSession;
    if (session != null) {
      return AuthStatus.authenticated(
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    }
    return const AuthStatus.unauthenticated();
  }

  /// 이메일/비밀번호로 로그인
  ///
  /// 성공 시 onAuthStateChange 스트림이 signedIn 이벤트를 발행하여
  /// 자동으로 authenticated 상태로 전환됩니다.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 회원가입
  ///
  /// 이메일 인증이 필요한 경우 signedIn 이벤트가 발행되지 않으므로
  /// 상태는 unauthenticated로 유지됩니다.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signOut();
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<void> resetPassword(String email) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AuthException(
        message: AuthErrorType.classify(e).localized,
        originalError: e,
      );
    }
  }

  /// 새 비밀번호로 업데이트 (비밀번호 재설정 링크를 통해 호출)
  Future<void> updatePassword(String newPassword) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
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

/// 현재 로그인 중인 사용자 정보 제공자
///
/// 사용 예:
/// ```dart
/// final user = ref.watch(currentUserProvider);
/// if (user != null) {
///   debugPrint('Email: ${user.email}');
/// }
/// ```
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authProvider).whenOrNull(
        authenticated: (user, token, refreshToken) => user,
      );
}

/// 현재 액세스 토큰 제공자
@riverpod
String? accessToken(Ref ref) {
  return ref.watch(authProvider).whenOrNull(
        authenticated: (user, token, refreshToken) => token,
      );
}

/// 인증 여부 확인
///
/// 사용 예:
/// ```dart
/// final isAuthenticated = ref.watch(isAuthenticatedProvider);
/// ```
@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authProvider).maybeWhen(
        authenticated: (user, token, refreshToken) => true,
        orElse: () => false,
      );
}

/// 인증 로딩 여부 확인
@riverpod
bool isAuthLoading(Ref ref) {
  return ref.watch(authProvider).maybeWhen(
        loading: () => true,
        orElse: () => false,
      );
}

/// 인증 에러 메시지 제공자
@riverpod
String? authError(Ref ref) {
  return ref.watch(authProvider).maybeWhen(
        error: (message, _) => message,
        orElse: () => null,
      );
}
