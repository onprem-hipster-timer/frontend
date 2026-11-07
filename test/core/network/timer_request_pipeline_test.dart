import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';
import 'package:momeet/core/network/dio_provider.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/network/timer_request.dart';
import 'package:momeet/core/network/timezone_interceptor.dart';
import 'package:momeet/core/providers/auth_provider.dart';

import '../../helpers/kratos_mocks.dart';

/// 첫 응답은 401, 그 뒤는 200과 한 시간 앞선 `Date` 헤더
class _FakeBackend implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final first = requests.length == 1;
    return ResponseBody.fromString(
      '{}',
      first ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (!first)
          'date': [
            formatHttpDate(DateTime.now().add(const Duration(hours: 1))),
          ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(registerKratosFallbacks);

  test('401 재시도를 거쳐도 타이머 요청 표시가 유지된다', () async {
    final harness = await KratosTestHarness.create();
    final clock = ServerClock();
    final backend = _FakeBackend();
    final dioProvider = Provider<Dio>((ref) {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.interceptors
        ..add(AuthInterceptor(ref, dio))
        ..add(TimezoneInterceptor())
        ..add(ServerClockInterceptor(clock));
      return dio..httpClientAdapter = backend;
    });
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    container.read(authProvider);
    await pumpEventQueue();
    harness.accessToken = testJwt();

    final response = await container
        .read(dioProvider)
        .fetch<dynamic>(timerRequest()..path = '/v1/timers');

    expect(response.statusCode, 200);
    expect(backend.requests, hasLength(2));
    expect(backend.requests.last.queryParameters['timezone'], 'UTC');
    expect(backend.requests.last.uri.queryParametersAll['timezone'], ['UTC']);
    expect(clock.offset.inSeconds, inInclusiveRange(3600 - 2, 3600 + 2));
  });
}
