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
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(message: message, code: code, stackTrace: stackTrace);
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    String? code,
    StackTrace? stackTrace,
  }) : super(message: message, code: code, stackTrace: stackTrace);
}

class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(message: message, code: code, stackTrace: stackTrace);
}

class ValidationException extends AppException {
  ValidationException({
    required String message,
    String? code,
    StackTrace? stackTrace,
  }) : super(message: message, code: code, stackTrace: stackTrace);
}
