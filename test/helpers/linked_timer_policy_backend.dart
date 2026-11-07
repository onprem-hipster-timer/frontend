import 'dart:typed_data';

import 'package:dio/dio.dart';

/// `linked_timer_policy` 없는 요청에는 422 `LinkedTimerPolicyRequiredError`, 있으면 204로 답한다.
///
/// ```dart
/// final backend = LinkedTimerPolicyBackend();
/// final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
///   ..httpClientAdapter = backend;
/// ```
class LinkedTimerPolicyBackend implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.queryParameters.containsKey('linked_timer_policy')) {
      return ResponseBody.fromString('', 204);
    }
    return ResponseBody.fromString(
      '{"status_code": 422, "error_type": "LinkedTimerPolicyRequiredError"}',
      422,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
