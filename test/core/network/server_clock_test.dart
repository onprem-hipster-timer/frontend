import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_parser/http_parser.dart';
import 'package:momeet/core/network/server_clock.dart';

/// 정해진 `Date` 헤더로 응답하는 백엔드 (null이면 헤더 없음)
class _FakeBackend implements HttpClientAdapter {
  _FakeBackend(this.date);

  final String? Function() date;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final date = this.date();
    return ResponseBody.fromString(
      '[]',
      200,
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
  group('ServerClock', () {
    final device = DateTime.utc(2026, 11, 6, 10, 0, 0);
    late ServerClock clock;

    setUp(() => clock = ServerClock(deviceNow: () => device));

    void sample(Duration serverAhead, {Duration rtt = Duration.zero}) {
      clock.addSample(
        serverDate: device.add(serverAhead),
        sentAt: device.subtract(rtt ~/ 2),
        receivedAt: device.add(rtt ~/ 2),
      );
    }

    test('표본이 없으면 기기 시각을 그대로 쓴다', () {
      expect(clock.offset, Duration.zero);
      expect(clock.now(), device);
    });

    test('Date의 초 미만 절사를 0.5초로 보정해 요청·응답의 가운데 시각과 비교한다', () {
      clock.addSample(
        serverDate: DateTime.utc(2026, 11, 6, 10, 5, 0),
        sentAt: DateTime.utc(2026, 11, 6, 10, 0, 0),
        receivedAt: DateTime.utc(2026, 11, 6, 10, 0, 1),
      );

      expect(clock.offset, const Duration(minutes: 5));
      expect(clock.now(), device.add(const Duration(minutes: 5)));
    });

    test('최근 표본의 중앙값을 써서 튀는 값 하나에 흔들리지 않는다', () {
      sample(const Duration(seconds: 30));
      sample(const Duration(seconds: 30));
      sample(const Duration(hours: 1));

      expect(clock.offset, const Duration(seconds: 30, milliseconds: 500));
    });

    test('최근 5개 표본만 쓴다', () {
      for (var i = 0; i < 3; i++) {
        sample(const Duration(hours: 1));
      }
      for (var i = 0; i < 5; i++) {
        sample(const Duration(seconds: -20));
      }

      expect(clock.offset, const Duration(seconds: -19, milliseconds: -500));
    });

    test('now()는 UTC다', () {
      final local = ServerClock(deviceNow: () => DateTime(2026, 11, 6, 19));

      expect(local.now().isUtc, isTrue);
    });
  });

  group('ServerClockInterceptor', () {
    late ServerClock clock;
    late Dio dio;
    String? date;

    setUp(() {
      clock = ServerClock();
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..interceptors.add(ServerClockInterceptor(clock))
        ..httpClientAdapter = _FakeBackend(() => date);
    });

    test('타이머 응답의 Date 헤더로 서버 시각을 맞춘다', () async {
      date = formatHttpDate(DateTime.now().add(const Duration(hours: 1)));

      await dio.get<dynamic>('/v1/timers');

      expect(clock.offset.inSeconds, inInclusiveRange(3600 - 2, 3600 + 2));
    });

    test('Date 헤더가 없는 응답은 건너뛴다', () async {
      date = null;

      await dio.get<dynamic>('/v1/timers');

      expect(clock.offset, Duration.zero);
    });

    test('타이머가 아닌 경로의 응답은 쓰지 않는다', () async {
      date = formatHttpDate(DateTime.now().add(const Duration(hours: 1)));

      await dio.get<dynamic>('/v1/todos');

      expect(clock.offset, Duration.zero);
    });
  });
}
