import 'package:dio/dio.dart';

/// 게스트 단계 요청이 Cloudflare Turnstile 토큰을 담는 헤더. backend는 토큰을 한 번만 받는다
const turnstileTokenHeader = 'X-Turnstile-Token';

/// Turnstile [token]을 담은 [RequestOptions]. `/v1/guests/*`의 게스트 단계(이름 찾기, 생성, 자기 삭제)에 쓴다
///
/// ```dart
/// options: turnstileRequest(token),
/// ```
RequestOptions turnstileRequest(String token) =>
    RequestOptions(headers: {turnstileTokenHeader: token});

/// 429 응답이 알려 준 다시 보낼 때까지의 시간. 본문의 `retry_after`(초), 없으면 `Retry-After` 헤더(초)다.
///
/// 웹에서는 다른 출처의 `Retry-After` 헤더를 읽을 수 없어(CORS가 내보내지 않음) 본문을 먼저 본다.
Duration? retryAfterOf(Response<Object?>? response) {
  final data = response?.data;
  final seconds = switch (data) {
    {'retry_after': final num value} => value.toInt(),
    _ => int.tryParse(response?.headers.value('retry-after') ?? ''),
  };
  return seconds == null || seconds < 0 ? null : Duration(seconds: seconds);
}
