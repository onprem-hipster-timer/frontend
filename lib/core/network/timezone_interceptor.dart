// 타이머 API 요청에 기기 타임존 쿼리 파라미터를 자동으로 추가하는 Interceptor

import 'package:dio/dio.dart';

import '../utils/timezone_utils.dart';

/// `/v1/timers` 경로 요청에 [timezone] 쿼리가 없으면 기기 타임존을 붙입니다.
/// 서버가 해당 타임존 기준으로 타임스탬프를 반환합니다.
class TimezoneInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.contains('/v1/timers') &&
        !options.queryParameters.containsKey('timezone')) {
      options.queryParameters['timezone'] = deviceTimezoneOffsetString();
    }
    handler.next(options);
  }
}
