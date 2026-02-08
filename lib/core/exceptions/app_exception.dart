/// 앱 전역 예외 처리
class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required super.message,
    this.statusCode,
    super.code,
    super.stackTrace,
  });
}

class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}

class ValidationException extends AppException {
  ValidationException({
    required super.message,
    super.code,
    super.stackTrace,
  });
}
