import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/network/timer_request.dart';

class _FakeBackend implements HttpClientAdapter {
  _FakeBackend(this.date, {this.statusCode = 200});

  final String? Function() date;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final date = this.date();
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (date != null) 'date': [date],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ServerClock 경계', () {
    final device = DateTime.utc(2026, 11, 6, 10, 0, 0);
    late ServerClock clock;

    setUp(() => clock = ServerClock(deviceNow: () => device));

    test('표본 하나면 그 값이 offset이다', () {
      clock.addSample(
        serverDate: device.subtract(const Duration(minutes: 3)),
        sentAt: device,
        receivedAt: device,
      );

      expect(
        clock.offset,
        const Duration(minutes: -3) + const Duration(milliseconds: 500),
      );
    });

    test('여섯 번째 표본이 들어오면 첫 표본은 버린다', () {
      void sample(Duration ahead) => clock.addSample(
        serverDate: device.add(ahead),
        sentAt: device,
        receivedAt: device,
      );

      sample(const Duration(hours: 1)); // 1번째: 버려져야 함
      for (var i = 0; i < 2; i++) {
        sample(const Duration(seconds: 10));
      }
      for (var i = 0; i < 3; i++) {
        sample(const Duration(seconds: 20));
      }

      // 남은 5개 = [10, 10, 20, 20, 20] → 중앙값 20
      expect(clock.offset, const Duration(seconds: 20, milliseconds: 500));
    });

    test('RTT가 커도 요청·응답 가운데 시각 기준이라 offset이 치우치지 않는다', () {
      clock.addSample(
        serverDate: device,
        sentAt: device.subtract(const Duration(seconds: 5)),
        receivedAt: device.add(const Duration(seconds: 5)),
      );

      expect(clock.offset, const Duration(milliseconds: 500));
    });
  });

  group('ServerClockInterceptor 경계', () {
    late ServerClock clock;

    Dio dio(String? Function() date, {int statusCode = 200}) =>
        Dio(BaseOptions(baseUrl: 'https://api.example.com'))
          ..interceptors.add(ServerClockInterceptor(clock))
          ..httpClientAdapter = _FakeBackend(date, statusCode: statusCode);

    setUp(() => clock = ServerClock());

    test('Date 헤더가 깨져 있으면 건너뛰고 요청은 성공한다', () async {
      final response = await dio(
        () => 'not a date',
      ).fetch<dynamic>(timerRequest()..path = '/v1/timers');

      expect(response.statusCode, 200);
      expect(clock.offset, Duration.zero);
    });
  });
}
