import 'package:dio/dio.dart';

const _kTimerRequest = 'timer_request';

/// 타이머 REST 요청임을 표시한 [RequestOptions]를 생성합니다.
///
/// 표시한 요청에는 `TimezoneInterceptor`가 `timezone=UTC`를 붙이고,
/// `ServerClockInterceptor`가 응답의 `Date` 헤더로 서버 시각을 맞춥니다.
///
/// ```dart
/// options: timerRequest(),
/// ```
RequestOptions timerRequest() => RequestOptions(extra: {_kTimerRequest: true});

/// [timerRequest]로 표시한 요청인지
bool isTimerRequest(RequestOptions options) =>
    options.extra[_kTimerRequest] == true;
