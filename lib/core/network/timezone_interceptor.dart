// 타이머 API 요청에 timezone=UTC 쿼리 파라미터를 자동으로 추가하는 Interceptor

import 'package:dio/dio.dart';

/// `/v1/timers`와 그 하위 경로(`/v1/timers/...`) 요청에 [timezone] 쿼리가 없으면 `UTC`를 붙입니다.
/// 실시간 이벤트의 시각이 UTC이므로 REST 응답도 같은 형식으로 받아 `updated_at`을 비교합니다.
class TimezoneInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final isTimerPath = path == '/v1/timers' || path.startsWith('/v1/timers/');
    if (isTimerPath && !options.queryParameters.containsKey('timezone')) {
      options.queryParameters['timezone'] = 'UTC';
    }
    handler.next(options);
  }
}
