import 'dart:ui' show PlatformDispatcher;

/// 앱 전역 예외 클래스들
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => message;
}

/// 네트워크 관련 예외
class NetworkException extends AppException {
  NetworkException({
    super.message = 'Please check your network connection',
    super.originalError,
  });
}

// ============================================================
// 인증 에러 유형 (로케일 기반 메시지 렌더링)
// ============================================================

/// Supabase 등 외부 인증 에러를 구조화한 유형
///
/// ```dart
/// final type = AuthErrorType.classify(supabaseError);
/// print(type.localized); // 한국어 or 영어 (플랫폼 로케일 기반)
/// ```
enum AuthErrorType {
  invalidCredentials,
  emailNotConfirmed,
  userNotFound,
  userAlreadyRegistered,
  tooManyRequests,
  weakPassword,
  networkError,
  unknown;

  /// 외부 에러 객체를 분석하여 적절한 AuthErrorType 반환
  static AuthErrorType classify(dynamic error) {
    if (error is NetworkException) return networkError;

    final msg = error.toString().toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return invalidCredentials;
    }
    if (msg.contains('email not confirmed')) return emailNotConfirmed;
    if (msg.contains('user not found') || msg.contains('no user found')) {
      return userNotFound;
    }
    if (msg.contains('user already registered')) return userAlreadyRegistered;
    if (msg.contains('too many requests') ||
        msg.contains('rate limit') ||
        msg.contains('request this once every')) {
      return tooManyRequests;
    }
    if (msg.contains('weak password') || msg.contains('should be at least')) {
      return weakPassword;
    }
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('clientexception')) {
      return networkError;
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
        emailNotConfirmed => '이메일 인증이 완료되지 않았습니다.\n메일함을 확인해주세요',
        userNotFound => '등록되지 않은 이메일입니다',
        userAlreadyRegistered => '이미 가입된 이메일입니다',
        tooManyRequests => '요청이 너무 많습니다.\n잠시 후 다시 시도해주세요',
        weakPassword => '비밀번호가 너무 짧습니다.\n6자 이상 입력해주세요',
        networkError => '네트워크 연결을 확인해주세요',
        unknown => '오류가 발생했습니다. 잠시 후 다시 시도해주세요',
      };

  String get _en => switch (this) {
        invalidCredentials => 'Invalid email or password',
        emailNotConfirmed =>
          'Email not confirmed.\nPlease check your inbox',
        userNotFound => 'No account found with this email',
        userAlreadyRegistered => 'This email is already registered',
        tooManyRequests => 'Too many requests.\nPlease try again later',
        weakPassword =>
          'Password is too short.\nPlease use at least 6 characters',
        networkError => 'Please check your network connection',
        unknown => 'An error occurred. Please try again later',
      };
}

/// 인증 관련 예외
class AuthException extends AppException {
  final AuthErrorType? errorType;

  AuthException({
    super.message = 'Authentication required',
    this.errorType,
    super.originalError,
  });

  @override
  String toString() => errorType?.localized ?? message;
}

/// 인증 토큰 만료 예외
class TokenExpiredException extends AuthException {
  TokenExpiredException({
    super.message = 'Session expired',
    super.originalError,
  });
}

/// 서버 오류
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    super.message = 'Server error',
    this.statusCode,
    super.originalError,
  });
}

/// 유효성 검증 오류
class ValidationException extends AppException {
  ValidationException({
    super.message = 'Invalid input',
    super.originalError,
  });
}

/// 리소스를 찾을 수 없음
class NotFoundException extends AppException {
  NotFoundException({
    super.message = 'Resource not found',
    super.originalError,
  });
}

/// 권한 부족
class PermissionException extends AppException {
  PermissionException({
    super.message = 'Permission denied',
    super.originalError,
  });
}

/// 알 수 없는 오류
class UnknownException extends AppException {
  UnknownException({
    super.message = 'An unknown error occurred',
    super.originalError,
  });
}
