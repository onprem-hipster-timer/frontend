import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// 가짜 시간(testWidgets)을 쓰는 테스트. testWidgets가 HttpClient를 막으므로
// 실제 소켓을 쓰는 테스트(timer_ws_client_test.dart)와 파일을 나눈다.
void main() {
  // ============================================================
  // TimerWsClient.reconnectDelay — 백오프 계산
  // ============================================================
  group('TimerWsClient.reconnectDelay', () {
    test('지터 최대치에서 1s부터 두 배씩 늘어난다', () {
      final delays = [
        for (var i = 0; i < 5; i++) TimerWsClient.reconnectDelay(i, 1),
      ];
      expect(delays, const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
      ]);
    });

    test('30s를 넘지 않는다', () {
      expect(TimerWsClient.reconnectDelay(5, 1), const Duration(seconds: 30));
      expect(TimerWsClient.reconnectDelay(100, 1), const Duration(seconds: 30));
    });

    test('지터 최소치에서는 기준값의 절반이다', () {
      expect(
        TimerWsClient.reconnectDelay(0, 0),
        const Duration(milliseconds: 500),
      );
      expect(TimerWsClient.reconnectDelay(100, 0), const Duration(seconds: 15));
    });
  });

  // ============================================================
  // TimerWsClient 재접속 — 가짜 채널 + 가짜 시간(testWidgets)
  // ============================================================
  group('TimerWsClient 재접속', () {
    late List<_FakeChannel> channels;

    // 지터 0 → 재접속 대기 = 기준값의 절반 (0.5s, 1s, 2s, …)
    TimerWsClient createClient({Future<String?> Function()? accessToken}) =>
        TimerWsClient(
          accessToken: accessToken ?? () async => 'jwt',
          refreshAccessToken: () async => 'jwt',
          connectChannel: (uri, protocols) {
            final channel = _FakeChannel();
            channels.add(channel);
            return channel;
          },
          random: _FixedRandom(0),
        );

    setUp(() {
      channels = [];
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test');
    });

    tearDown(dotenv.clean);

    for (final code in <int?>[1000, 1001, 1006, 1011, 4029, null]) {
      testWidgets('서버가 끊으면(close code: $code) 백오프 후 다시 연결한다', (tester) async {
        final client = createClient();
        await tester.pump();
        expect(channels, hasLength(1));

        channels.last.serverClose(code);
        await tester.pump(const Duration(milliseconds: 499));
        expect(channels, hasLength(1));

        await tester.pump(const Duration(milliseconds: 1));
        expect(channels, hasLength(2));

        client.dispose();
      });
    }

    testWidgets('연속 실패하면 대기 시간이 두 배로 늘어난다', (tester) async {
      final client = createClient();
      await tester.pump();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 500));
      expect(channels, hasLength(2));

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 999));
      expect(channels, hasLength(2));
      await tester.pump(const Duration(milliseconds: 1));
      expect(channels, hasLength(3));

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(channels, hasLength(3));
      await tester.pump(const Duration(milliseconds: 1));
      expect(channels, hasLength(4));

      client.dispose();
    });

    testWidgets('횟수 제한 없이 계속 재접속한다', (tester) async {
      final client = createClient();
      await tester.pump();

      for (var i = 0; i < 10; i++) {
        channels.last.serverClose(1006);
        await tester.pump(const Duration(seconds: 30));
      }
      expect(channels, hasLength(11));

      client.dispose();
    });

    testWidgets('connected를 받으면 백오프가 처음으로 돌아간다', (tester) async {
      final client = createClient();
      await tester.pump();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 500));
      channels.last.serverClose(1006);
      await tester.pump(const Duration(seconds: 1));
      expect(channels, hasLength(3));

      channels.last.serverSend(jsonEncode(_connected));
      await tester.pump();
      channels.last.serverClose(1001);
      await tester.pump(const Duration(milliseconds: 500));
      expect(channels, hasLength(4));

      client.dispose();
    });

    testWidgets('재접속하면 connected를 다시 내보내 REST로 다시 맞추게 한다', (tester) async {
      final client = createClient();
      final events = <TimerWsEvent>[];
      client.messageStream.listen(events.add);
      await tester.pump();

      channels.last.serverSend(jsonEncode(_connected));
      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 500));
      channels.last.serverSend(jsonEncode(_connected));
      await tester.pump();

      expect(events.whereType<TimerWsConnected>(), hasLength(2));
      expect(client.isConnected, isTrue);

      client.dispose();
    });

    testWidgets('재접속 대기 중 reconnectNow하면 기다리지 않고 바로 연결한다', (tester) async {
      final client = createClient();
      await tester.pump();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 100));
      client.reconnectNow();
      await tester.pump();
      expect(channels, hasLength(2));

      // 예약돼 있던 재접속은 취소된다
      await tester.pump(const Duration(seconds: 1));
      expect(channels, hasLength(2));

      client.dispose();
    });

    testWidgets('연결돼 있으면 reconnectNow는 아무것도 하지 않는다', (tester) async {
      final client = createClient();
      await tester.pump();

      client.reconnectNow();
      await tester.pump();

      expect(channels, hasLength(1));
      client.dispose();
    });

    testWidgets('JWT를 받는 중에 reconnectNow가 와도 연결은 하나만 연다', (tester) async {
      final token = Completer<String?>();
      final client = createClient(accessToken: () => token.future);

      client.reconnectNow();
      token.complete('jwt');
      await tester.pump();

      expect(channels, hasLength(1));
      client.dispose();
    });

    testWidgets('disconnect하면 채널을 닫고 재접속하지 않는다', (tester) async {
      final client = createClient();
      await tester.pump();
      final channel = channels.last;

      client.disconnect();
      channel.serverClose(1000);
      client.reconnectNow();
      await tester.pump(const Duration(seconds: 60));

      expect(channel.sink.closed, isTrue);
      expect(channels, hasLength(1));

      client.dispose();
    });

    testWidgets('재접속 대기 중 disconnect하면 예약된 재접속이 취소된다', (tester) async {
      final client = createClient();
      await tester.pump();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 100));
      client.disconnect();
      await tester.pump(const Duration(seconds: 60));

      expect(channels, hasLength(1));

      client.dispose();
    });

    testWidgets('재접속 대기 중 dispose하면 예약된 재접속이 취소된다', (tester) async {
      final client = createClient();
      await tester.pump();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 100));
      client.dispose();
      await tester.pump(const Duration(seconds: 60));

      expect(channels, hasLength(1));
    });
  });
}

const _connected = <String, Object?>{
  'id': 'c1',
  'type': 'connected',
  'from_user': null,
  'timestamp': '2026-11-06T10:30:00+0000',
  'payload': <String, Object?>{},
};

class _FixedRandom extends Fake implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;
}

class _FakeSink extends Fake implements WebSocketSink {
  bool closed = false;
  final added = <Object?>[];

  @override
  void add(Object? data) => added.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }
}

/// 서버 쪽 동작(메시지 전송, 연결 종료)을 테스트에서 흉내 내는 채널
class _FakeChannel extends Fake implements WebSocketChannel {
  final _incoming = StreamController<dynamic>();

  @override
  final _FakeSink sink = _FakeSink();

  @override
  int? closeCode;

  @override
  String? get closeReason => null;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  void serverSend(String message) => _incoming.add(message);

  void serverClose(int? code) {
    closeCode = code;
    _incoming.close();
  }
}
