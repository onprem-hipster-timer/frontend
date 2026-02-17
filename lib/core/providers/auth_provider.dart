// 인증 상태 관리 프로바이더 (Supabase)
//
// 이 파일은 다음을 관리합니다:
// - Supabase 인증 상태
// - JWT 토큰 관리
// - 사용자 세션
// - 로그인/로그아웃 로직

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/exceptions/exceptions.dart';

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
    return _initializeAuth();
  }

  /// 인증 상태 초기화 (build에서 호출)
  AuthStatus _initializeAuth() {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final session = supabase.auth.currentSession;

      if (session != null) {
        final token = session.accessToken;

        if (AppConfig.enableDebugLogging) {
          debugPrint('✅ [AUTH] Session restored for ${session.user.email}');
        }

        return AuthStatus.authenticated(
          user: session.user,
          accessToken: token,
          refreshToken: session.refreshToken,
        );
      } else {
        if (AppConfig.enableDebugLogging) {
          debugPrint('❌ [AUTH] No active session');
        }
        return const AuthStatus.unauthenticated();
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('❌ [AUTH] Initialization error: $e');
      }
      return AuthStatus.error(
        message: 'Failed to initialize authentication',
        originalError: e,
      );
    }
  }

  /// 이메일/비밀번호로 로그인
  ///
  /// 성공 시 authProvider가 authenticated 상태로 변경됩니다.
  /// 토큰은 accessTokenProvider를 통해 자동으로 파생됩니다.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthStatus.loading();

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && response.user != null) {
        final token = response.session!.accessToken;

        state = AuthStatus.authenticated(
          user: response.user!,
          accessToken: token,
          refreshToken: response.session!.refreshToken,
        );

        if (AppConfig.enableDebugLogging) {
          debugPrint('✅ [AUTH] Signed in: ${response.user!.email}');
        }
      } else {
        throw AuthException(message: '로그인에 실패했습니다');
      }
    } on AuthException catch (e) {
      state = AuthStatus.error(message: e.message, originalError: e);
      rethrow;
    } catch (e) {
      final message = _parseError(e);
      state = AuthStatus.error(message: message, originalError: e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 회원가입
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthStatus.loading();

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (AppConfig.enableDebugLogging) {
          debugPrint('✅ [AUTH] Signed up: ${response.user!.email}');
        }

        // 회원가입 후 자동 로그인되지 않을 수 있으므로, 이메일 인증 후 로그인 필요
        state = const AuthStatus.unauthenticated();
      } else {
        throw AuthException(message: '회원가입에 실패했습니다');
      }
    } on AuthException catch (e) {
      state = AuthStatus.error(message: e.message, originalError: e);
      rethrow;
    } catch (e) {
      final message = _parseError(e);
      state = AuthStatus.error(message: message, originalError: e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signOut();

      state = const AuthStatus.unauthenticated();

      if (AppConfig.enableDebugLogging) {
        debugPrint('✅ [AUTH] Signed out');
      }
    } catch (e) {
      final message = _parseError(e);
      state = AuthStatus.error(message: message, originalError: e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<void> resetPassword(String email) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.resetPasswordForEmail(email);

      if (AppConfig.enableDebugLogging) {
        debugPrint('✅ [AUTH] Password reset email sent to $email');
      }
    } catch (e) {
      final message = _parseError(e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 새 비밀번호로 업데이트 (비밀번호 재설정 링크를 통해 호출)
  Future<void> updatePassword(String newPassword) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (AppConfig.enableDebugLogging) {
        debugPrint('✅ [AUTH] Password updated');
      }
    } catch (e) {
      final message = _parseError(e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 토큰 갱신
  Future<String?> refreshAccessToken() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final session = supabase.auth.currentSession;

      if (session?.refreshToken != null) {
        final response = await supabase.auth.refreshSession();

        if (response.session?.accessToken != null) {
          final newToken = response.session!.accessToken;

          // authProvider를 갱신하여 accessTokenProvider에 자동 반영
          state = AuthStatus.authenticated(
            user: response.session!.user,
            accessToken: newToken,
            refreshToken: response.session!.refreshToken,
          );

          if (AppConfig.enableDebugLogging) {
            debugPrint('✅ [AUTH] Token refreshed');
          }

          return newToken;
        }
      }

      return null;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        debugPrint('❌ [AUTH] Token refresh failed: $e');
      }

      // 토큰 갱신 실패 시 로그아웃
      await signOut();
      return null;
    }
  }

  /// 에러 메시지 파싱
  String _parseError(dynamic error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is NetworkException) {
      return error.message;
    } else {
      return '알 수 없는 오류가 발생했습니다';
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
