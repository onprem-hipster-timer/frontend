import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';
import 'package:momeet/core/network/server_clock.dart';

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
      final response = await dio(() => 'not a date').get<dynamic>('/v1/timers');

      expect(response.statusCode, 200);
      expect(clock.offset, Duration.zero);
    });

    test('타이머 명령 경로(/v1/timers/{id}/pause)의 응답도 쓴다', () async {
      final ahead = formatHttpDate(
        DateTime.now().add(const Duration(minutes: 10)),
      );

      await dio(() => ahead).patch<dynamic>('/v1/timers/t1/pause');

      expect(clock.offset.inSeconds, inInclusiveRange(600 - 2, 600 + 2));
    });

    test('/v1/timers로 시작하는 다른 리소스 이름은 쓰지 않는다', () async {
      final ahead = formatHttpDate(
        DateTime.now().add(const Duration(minutes: 10)),
      );

      await dio(() => ahead).get<dynamic>('/v1/timersheets');

      expect(clock.offset, Duration.zero);
    });
  });
}
