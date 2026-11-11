import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/retry_policy.dart';

void main() {
  final request = RequestOptions(path: '/v1/todos');

  DioException failure(DioExceptionType type, {int? status}) => DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: request, statusCode: status),
  );

  test('연결 실패는 0.5·1·1.5초 뒤 세 번 다시 받고 3초 안에 멈춘다', () {
    final error = failure(DioExceptionType.connectionError);
    final delays = [for (var i = 0; i < 4; i++) appRetry(i, error)];

    expect(delays, [
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
      const Duration(milliseconds: 1500),
      null,
    ]);
    final total = delays.whereType<Duration>().fold(
      Duration.zero,
      (a, b) => a + b,
    );
    expect(total, appRetryWindow);
  });

  test('시간 초과와 서버가 깨어나는 동안의 502·503·504도 다시 받는다', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(appRetry(0, failure(type)), isNotNull, reason: '$type');
    }
    for (final status in [502, 503, 504]) {
      expect(
        appRetry(0, failure(DioExceptionType.badResponse, status: status)),
        isNotNull,
        reason: '$status',
      );
    }
  });

  test('서버가 답한 그 밖의 오류와 앱 오류는 다시 받지 않는다', () {
    for (final status in [400, 401, 404, 422, 500]) {
      expect(
        appRetry(0, failure(DioExceptionType.badResponse, status: status)),
        isNull,
        reason: '$status',
      );
    }
    expect(appRetry(0, failure(DioExceptionType.cancel)), isNull);
    expect(appRetry(0, Exception('잘못된 값')), isNull);
    expect(appRetry(0, StateError('버그')), isNull);
  });
}
