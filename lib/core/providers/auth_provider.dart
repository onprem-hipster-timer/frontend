/// 인증 상태 관리 프로바이더 (Supabase)
///
/// 이 파일은 다음을 관리합니다:
/// - Supabase 인증 상태
/// - JWT 토큰 관리
/// - 사용자 세션
/// - 로그인/로그아웃 로직

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/exceptions/exceptions.dart';
import 'package:momeet/core/network/dio_provider.dart';

part 'auth_provider.freezed.dart';

// ============================================================
// 상태 모델
// ============================================================

/// 인증 상태
@freezed
class AuthState with _$AuthState {
  /// 인증 대기 중 (초기 로딩)
  const factory AuthState.loading() = AuthLoading;

  /// 인증됨 (로그인함)
  const factory AuthState.authenticated({
    required User user,
    required String accessToken,
    String? refreshToken,
  }) = AuthAuthenticated;

  /// 미인증 (로그인하지 않음)
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// 에러
  const factory AuthState.error({
    required String message,
    dynamic originalError,
  }) = AuthError;
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
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ============================================================
// 인증 상태 프로바이더
// ============================================================

/// 현재 인증 상태를 제공하는 AsyncNotifier
///
/// 사용 예:
/// ```dart
/// final state = ref.watch(authStateProvider);
/// state.whenData((authState) {
///   authState.maybeWhen(
///     authenticated: (user, token, refreshToken) {
///       print('로그인됨: ${user.email}');
///     },
///     unauthenticated: () {
///       print('로그아웃됨');
///     },
///     loading: () => showLoader(),
///     error: (message, error) => showError(message),
///   );
/// });
/// ```
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

/// 인증 상태를 관리하는 StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState.loading()) {
    _initializeAuth();
  }

  /// 인증 상태 초기화 (앱 시작 시 자동 호출)
  void _initializeAuth() {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final session = supabase.auth.currentSession;

      if (session != null && session.user != null) {
        final token = session.accessToken;
        ref.read(authTokenProvider.notifier).state = token;

        state = AuthState.authenticated(
          user: session.user!,
          accessToken: token,
          refreshToken: session.refreshToken,
        );

        if (AppConfig.enableDebugLogging) {
          print('✅ [AUTH] Session restored for ${session.user!.email}');
        }
      } else {
        state = const AuthState.unauthenticated();
        if (AppConfig.enableDebugLogging) {
          print('❌ [AUTH] No active session');
        }
      }
    } catch (e) {
      state = AuthState.error(
        message: 'Failed to initialize authentication',
        originalError: e,
      );
      if (AppConfig.enableDebugLogging) {
        print('❌ [AUTH] Initialization error: $e');
      }
    }
  }

  /// 이메일/비밀번호로 로그인
  ///
  /// 성공 시 authStateProvider가 authenticated 상태로 변경됩니다.
  /// 토큰은 자동으로 authTokenProvider에 저장됩니다.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && response.user != null) {
        final token = response.session!.accessToken;

        // 토큰을 authTokenProvider에 저장 (Dio Interceptor에서 사용)
        ref.read(authTokenProvider.notifier).state = token;

        state = AuthState.authenticated(
          user: response.user!,
          accessToken: token,
          refreshToken: response.session!.refreshToken,
        );

        if (AppConfig.enableDebugLogging) {
          print('✅ [AUTH] Signed in: ${response.user!.email}');
        }
      } else {
        throw AuthException(message: '로그인에 실패했습니다');
      }
    } on AuthException catch (e) {
      state = AuthState.error(message: e.message, originalError: e);
      rethrow;
    } catch (e) {
      final message = _parseError(e);
      state = AuthState.error(message: message, originalError: e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 회원가입
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (AppConfig.enableDebugLogging) {
          print('✅ [AUTH] Signed up: ${response.user!.email}');
        }

        // 회원가입 후 자동 로그인되지 않을 수 있으므로, 이메일 인증 후 로그인 필요
        state = const AuthState.unauthenticated();
      } else {
        throw AuthException(message: '회원가입에 실패했습니다');
      }
    } on AuthException catch (e) {
      state = AuthState.error(message: e.message, originalError: e);
      rethrow;
    } catch (e) {
      final message = _parseError(e);
      state = AuthState.error(message: message, originalError: e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.signOut();

      // 토큰 제거
      ref.read(authTokenProvider.notifier).state = null;

      state = const AuthState.unauthenticated();

      if (AppConfig.enableDebugLogging) {
        print('✅ [AUTH] Signed out');
      }
    } catch (e) {
      final message = _parseError(e);
      state = AuthState.error(message: message, originalError: e);
      throw AuthException(message: message, originalError: e);
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<void> resetPassword(String email) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.resetPasswordForEmail(email);

      if (AppConfig.enableDebugLogging) {
        print('✅ [AUTH] Password reset email sent to $email');
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
        print('✅ [AUTH] Password updated');
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

          // 새 토큰 저장
          ref.read(authTokenProvider.notifier).state = newToken;

          if (AppConfig.enableDebugLogging) {
            print('✅ [AUTH] Token refreshed');
          }

          return newToken;
        }
      }

      return null;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('❌ [AUTH] Token refresh failed: $e');
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
    } else if (error is AuthError) {
      // Supabase AuthError 처리
      return error.message ?? '인증 오류가 발생했습니다';
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
///   print('Email: ${user.email}');
/// }
/// ```
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).whenOrNull(
        authenticated: (user, _, __) => user,
      );
});

/// 현재 액세스 토큰 제공자
final accessTokenProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).whenOrNull(
        authenticated: (_, token, __) => token,
      );
});

/// 인증 여부 확인
///
/// 사용 예:
/// ```dart
/// final isAuthenticated = ref.watch(isAuthenticatedProvider);
/// ```
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        authenticated: (_, __, ___) => true,
        orElse: () => false,
      );
});

/// 인증 로딩 여부 확인
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        loading: () => true,
        orElse: () => false,
      );
});

/// 인증 에러 메시지 제공자
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        error: (message, _) => message,
        orElse: () => null,
      );
});
