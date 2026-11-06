import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/timezone_interceptor.dart';

class _Handler extends RequestInterceptorHandler {
  RequestOptions? forwarded;

  @override
  void next(RequestOptions requestOptions) => forwarded = requestOptions;
}

void main() {
  RequestOptions intercept(String path, [Map<String, dynamic>? query]) {
    final handler = _Handler();
    TimezoneInterceptor().onRequest(
      RequestOptions(path: path, queryParameters: query),
      handler,
    );
    return handler.forwarded!;
  }

  test('타이머 요청에 timezone=UTC를 붙인다', () {
    expect(intercept('/v1/timers/t1/pause').queryParameters['timezone'], 'UTC');
  });

  test('timezone을 이미 지정했으면 바꾸지 않는다', () {
    final options = intercept('/v1/timers', {'timezone': '+09:00'});
    expect(options.queryParameters['timezone'], '+09:00');
  });

  test('타이머가 아닌 요청에는 붙이지 않는다', () {
    expect(intercept('/v1/todos').queryParameters, isNot(contains('timezone')));
  });

  test('/v1/timers로 시작하는 다른 리소스 이름에는 붙이지 않는다', () {
    expect(
      intercept('/v1/timersheets').queryParameters,
      isNot(contains('timezone')),
    );
  });
}
