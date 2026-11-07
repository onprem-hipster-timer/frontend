import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/timer_request.dart';
import 'package:momeet/core/network/timezone_interceptor.dart';

class _Handler extends RequestInterceptorHandler {
  RequestOptions? forwarded;

  @override
  void next(RequestOptions requestOptions) => forwarded = requestOptions;
}

void main() {
  RequestOptions intercept(RequestOptions options) {
    final handler = _Handler();
    TimezoneInterceptor().onRequest(options, handler);
    return handler.forwarded!;
  }

  test('타이머 요청으로 표시하면 timezone=UTC를 붙인다', () {
    final options = intercept(timerRequest()..path = '/v1/timers/t1/pause');
    expect(options.queryParameters['timezone'], 'UTC');
  });

  test('timezone을 이미 지정했으면 바꾸지 않는다', () {
    final options = intercept(
      timerRequest()
        ..path = '/v1/timers'
        ..queryParameters['timezone'] = '+09:00',
    );
    expect(options.queryParameters['timezone'], '+09:00');
  });

  test('표시하지 않은 요청에는 타이머 경로여도 붙이지 않는다', () {
    expect(
      intercept(RequestOptions(path: '/v1/timers')).queryParameters,
      isNot(contains('timezone')),
    );
  });
}
