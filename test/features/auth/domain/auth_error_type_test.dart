import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/features/auth/domain/auth_error_type.dart';

import '../../../helpers/kratos_mocks.dart';

void main() {
  group('Kratos 메시지 ID', () {
    final cases = {
      4000006: AuthErrorType.invalidCredentials,
      4000007: AuthErrorType.userAlreadyRegistered,
      4000040: AuthErrorType.invalidEmail,
      4000032: AuthErrorType.passwordTooShort,
      4000033: AuthErrorType.passwordTooLong,
      4000031: AuthErrorType.passwordTooSimilar,
      4000034: AuthErrorType.passwordBreached,
      4060006: AuthErrorType.invalidCode,
      4070006: AuthErrorType.invalidCode,
      4000001: AuthErrorType.unknown,
    };
    for (final MapEntry(key: id, value: type) in cases.entries) {
      test('$id → ${type.name}', () {
        expect(AuthErrorType.classify(kratosError(id)), type);
      });
    }
  });

  group('Kratos 오류 ID와 상태 코드', () {
    test('만료된 플로우', () {
      expect(
        AuthErrorType.classify(
          const KratosException(
            statusCode: 410,
            errorId: 'self_service_flow_expired',
          ),
        ),
        AuthErrorType.flowExpired,
      );
    });

    test('재인증 필요', () {
      expect(
        AuthErrorType.classify(
          const KratosException(
            statusCode: 403,
            errorId: 'session_refresh_required',
          ),
        ),
        AuthErrorType.sessionRefreshRequired,
      );
    });

    test('이메일 인증 전 로그인', () {
      expect(
        AuthErrorType.classify(
          const KratosException(
            statusCode: 403,
            errorId: 'session_verified_address_required',
          ),
        ),
        AuthErrorType.emailNotVerified,
      );
    });

    test('429', () {
      expect(
        AuthErrorType.classify(const KratosException(statusCode: 429)),
        AuthErrorType.tooManyRequests,
      );
    });
  });

  group('네트워크 오류', () {
    DioException dioError(DioExceptionType type) =>
        DioException(requestOptions: RequestOptions(), type: type);

    test('연결 실패와 시간 초과는 네트워크 오류다', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        expect(
          AuthErrorType.classify(dioError(type)),
          AuthErrorType.networkError,
        );
      }
    });

    test('취소 등 나머지는 unknown이다', () {
      expect(
        AuthErrorType.classify(dioError(DioExceptionType.cancel)),
        AuthErrorType.unknown,
      );
    });
  });

  test('모르는 오류는 unknown이다', () {
    expect(AuthErrorType.classify(StateError('x')), AuthErrorType.unknown);
  });
}
