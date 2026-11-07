// 타이머 API 요청에 timezone=UTC 쿼리 파라미터를 자동으로 추가하는 Interceptor

import 'package:dio/dio.dart';
import 'package:momeet/core/network/timer_request.dart';

/// [timerRequest]로 표시한 요청에 [timezone] 쿼리가 없으면 `UTC`를 붙입니다.
/// 실시간 이벤트의 시각이 UTC이므로 REST 응답도 같은 형식으로 받아 `updated_at`을 비교합니다.
class TimezoneInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (isTimerRequest(options) &&
        !options.queryParameters.containsKey('timezone')) {
      options.queryParameters['timezone'] = 'UTC';
    }
    handler.next(options);
  }
}
