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
    super.message = '네트워크 연결을 확인해주세요',
    super.originalError,
  });
}

/// 인증 관련 예외
class AuthException extends AppException {
  AuthException({
    super.message = '로그인이 필요합니다',
    super.originalError,
  });
}

/// 인증 토큰 만료 예외
class TokenExpiredException extends AuthException {
  TokenExpiredException({
    super.message = '인증 토큰이 만료되었습니다',
    super.originalError,
  });
}

/// 서버 오류
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    super.message = '서버 오류가 발생했습니다',
    this.statusCode,
    super.originalError,
  });
}

/// 유효성 검증 오류
class ValidationException extends AppException {
  ValidationException({
    super.message = '입력값이 유효하지 않습니다',
    super.originalError,
  });
}

/// 리소스를 찾을 수 없음
class NotFoundException extends AppException {
  NotFoundException({
    super.message = '요청한 리소스를 찾을 수 없습니다',
    super.originalError,
  });
}

/// 권한 부족
class PermissionException extends AppException {
  PermissionException({
    super.message = '이 작업을 수행할 권한이 없습니다',
    super.originalError,
  });
}

/// 알 수 없는 오류
class UnknownException extends AppException {
  UnknownException({
    super.message = '알 수 없는 오류가 발생했습니다',
    super.originalError,
  });
}
