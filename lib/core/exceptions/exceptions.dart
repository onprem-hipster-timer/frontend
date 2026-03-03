import 'dart:ui' show PlatformDispatcher;

String _l(String ko, String en) {
  return PlatformDispatcher.instance.locale.languageCode == 'ko' ? ko : en;
}

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
    String? message,
    super.originalError,
  }) : super(
            message: message ??
                _l('네트워크 연결을 확인해주세요', 'Please check your network connection'));
}

/// 인증 관련 예외
class AuthException extends AppException {
  AuthException({
    String? message,
    super.originalError,
  }) : super(message: message ?? _l('로그인이 필요합니다', 'Authentication required'));
}

/// 인증 토큰 만료 예외
class TokenExpiredException extends AuthException {
  TokenExpiredException({
    String? message,
    super.originalError,
  }) : super(
            message:
                message ?? _l('인증이 만료되었습니다. 다시 로그인해주세요', 'Session expired'));
}

/// 서버 오류
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    String? message,
    this.statusCode,
    super.originalError,
  }) : super(message: message ?? _l('서버 오류가 발생했습니다', 'Server error'));
}

/// 유효성 검증 오류
class ValidationException extends AppException {
  ValidationException({
    String? message,
    super.originalError,
  }) : super(message: message ?? _l('입력값이 유효하지 않습니다', 'Invalid input'));
}

/// 리소스를 찾을 수 없음
class NotFoundException extends AppException {
  NotFoundException({
    String? message,
    super.originalError,
  }) : super(
            message: message ?? _l('요청한 리소스를 찾을 수 없습니다', 'Resource not found'));
}

/// 권한 부족
class PermissionException extends AppException {
  PermissionException({
    String? message,
    super.originalError,
  }) : super(message: message ?? _l('이 작업을 수행할 권한이 없습니다', 'Permission denied'));
}

/// 알 수 없는 오류
class UnknownException extends AppException {
  UnknownException({
    String? message,
    super.originalError,
  }) : super(
            message: message ??
                _l('알 수 없는 오류가 발생했습니다', 'An unknown error occurred'));
}
