import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:momeet/core/auth/kratos_models.dart';

/// 인증 오류 유형. Kratos의 메시지 ID·오류 ID와 네트워크 오류를 분류한다.
///
/// ```dart
/// final type = AuthErrorType.classify(error);
/// print(type.localized); // 한국어 or 영어 (플랫폼 로케일 기반)
/// ```
enum AuthErrorType {
  invalidCredentials,
  userAlreadyRegistered,
  invalidEmail,
  passwordTooShort,
  passwordTooLong,
  passwordTooSimilar,
  passwordBreached,
  invalidCode,
  flowExpired,
  sessionRefreshRequired,
  tooManyRequests,
  networkError,
  unknown;

  /// 외부 에러 객체를 분석하여 적절한 AuthErrorType 반환
  static AuthErrorType classify(Object? error) {
    if (error is KratosException) {
      if (error.statusCode == 429) return tooManyRequests;
      switch (error.errorId) {
        case 'self_service_flow_expired':
          return flowExpired;
        case 'session_refresh_required':
          return sessionRefreshRequired;
      }
      // Kratos text ID (로컬 Kratos v26.2.0에서 확인)
      return switch (error.messageId) {
        4000006 => invalidCredentials,
        4000007 => userAlreadyRegistered,
        4000040 => invalidEmail,
        4000032 => passwordTooShort,
        4000033 => passwordTooLong,
        4000031 => passwordTooSimilar,
        4000034 => passwordBreached,
        4060006 || 4070006 => invalidCode,
        _ => unknown,
      };
    }
    if (error is DioException) {
      if (error.response?.statusCode == 429) return tooManyRequests;
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.connectionError => networkError,
        _ => unknown,
      };
    }
    return unknown;
  }

  /// 플랫폼 로케일에 따라 지역화된 메시지 반환
  String get localized {
    final lang = PlatformDispatcher.instance.locale.languageCode;
    return lang == 'ko' ? _ko : _en;
  }

  String get _ko => switch (this) {
    invalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다',
    userAlreadyRegistered => '이미 가입된 이메일입니다',
    invalidEmail => '올바른 이메일 주소를 입력해주세요',
    passwordTooShort => '비밀번호는 8자 이상이어야 합니다',
    passwordTooLong => '비밀번호는 72자 이하여야 합니다',
    passwordTooSimilar => '이메일과 비슷한 비밀번호는 쓸 수 없습니다',
    passwordBreached => '유출된 적이 있는 비밀번호입니다.\n다른 비밀번호를 사용해주세요',
    invalidCode => '코드가 올바르지 않거나 이미 사용되었습니다',
    flowExpired => '요청 시간이 지났습니다.\n처음부터 다시 시도해주세요',
    sessionRefreshRequired => '보안을 위해 다시 로그인한 뒤 시도해주세요',
    tooManyRequests => '요청이 너무 많습니다.\n잠시 후 다시 시도해주세요',
    networkError => '네트워크 연결을 확인해주세요',
    unknown => '오류가 발생했습니다. 잠시 후 다시 시도해주세요',
  };

  String get _en => switch (this) {
    invalidCredentials => 'Invalid email or password',
    userAlreadyRegistered => 'This email is already registered',
    invalidEmail => 'Enter a valid email address',
    passwordTooShort => 'Password must be at least 8 characters',
    passwordTooLong => 'Password must be at most 72 characters',
    passwordTooSimilar => 'Password is too similar to your email',
    passwordBreached =>
      'This password has appeared in a data breach.\nPlease choose another',
    invalidCode => 'The code is invalid or has already been used',
    flowExpired => 'The request expired.\nPlease start over',
    sessionRefreshRequired => 'Please sign in again and retry',
    tooManyRequests => 'Too many requests.\nPlease try again later',
    networkError => 'Please check your network connection',
    unknown => 'An error occurred. Please try again later',
  };
}
