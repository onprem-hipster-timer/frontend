import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  // ============================================================
  // TimerWsClient.wsUrl — 정적 메서드
  // ============================================================
  group('TimerWsClient.wsUrl', () {
    test('https를 wss로 변환한다', () {
      expect(
        TimerWsClient.wsUrl('https://api.momeet.date'),
        'wss://api.momeet.date/v1/ws/timers',
      );
    });

    test('http를 ws로 변환한다', () {
      expect(
        TimerWsClient.wsUrl('http://localhost:2614'),
        'ws://localhost:2614/v1/ws/timers',
      );
    });

    test('기본 포트(443)는 생략된다', () {
      expect(
        TimerWsClient.wsUrl('https://api.example.com:443'),
        'wss://api.example.com/v1/ws/timers',
      );
    });

    test('비표준 포트를 유지한다', () {
      expect(
        TimerWsClient.wsUrl('http://localhost:8080'),
        'ws://localhost:8080/v1/ws/timers',
      );
    });

    test('timezone 쿼리 파라미터를 추가한다', () {
      final url = TimerWsClient.wsUrl(
        'https://api.momeet.date',
        timezone: 'Asia/Seoul',
      );
      expect(url, 'wss://api.momeet.date/v1/ws/timers?timezone=Asia%2FSeoul');
    });

    test('UTC offset 형식의 timezone도 인코딩한다', () {
      final url = TimerWsClient.wsUrl(
        'https://api.momeet.date',
        timezone: '+09:00',
      );
      expect(url, contains('timezone=%2B09%3A00'));
    });

    test('timezone이 null이면 쿼리 파라미터가 없다', () {
      final url = TimerWsClient.wsUrl('https://api.momeet.date');
      expect(url, isNot(contains('?')));
    });

    test('timezone이 빈 문자열이면 쿼리 파라미터가 없다', () {
      final url = TimerWsClient.wsUrl('https://api.momeet.date', timezone: '');
      expect(url, isNot(contains('?')));
    });

    test('baseUrl에 기존 경로가 있어도 /v1/ws/timers만 사용한다', () {
      final url = TimerWsClient.wsUrl('https://api.momeet.date/some/path');
      expect(url, 'wss://api.momeet.date/v1/ws/timers');
    });

    test('baseUrl에 trailing slash가 있어도 정상 동작한다', () {
      final url = TimerWsClient.wsUrl('https://api.momeet.date/');
      expect(url, 'wss://api.momeet.date/v1/ws/timers');
    });
  });

  // ============================================================
  // TimerWsClient.authProtocols — 인증 서브프로토콜
  // ============================================================
  group('TimerWsClient.authProtocols', () {
    test('JWT 토큰을 Sec-WebSocket-Protocol 형식으로 변환한다', () {
      final protocols = TimerWsClient.authProtocols('my-jwt-token');
      expect(protocols, ['authorization.bearer.my-jwt-token']);
    });

    test('토큰에 특수문자가 포함되어도 그대로 사용한다', () {
      final protocols = TimerWsClient.authProtocols('eyJ.abc.xyz');
      expect(protocols, ['authorization.bearer.eyJ.abc.xyz']);
    });

    test('항상 단일 요소 리스트를 반환한다', () {
      expect(TimerWsClient.authProtocols('any-token').length, 1);
    });
  });

  // ============================================================
  // TimerWsClient 토큰 저장 — autoConnect: false
  // ============================================================
  group('TimerWsClient 토큰 저장', () {
    test('생성 시 전달된 토큰이 저장된다', () {
      final client = TimerWsClient(accessToken: 'jwt-123', autoConnect: false);
      addTearDown(client.dispose);

      expect(client.token, 'jwt-123');
    });

    test('서로 다른 토큰으로 생성하면 각각 저장된다', () {
      final client1 = TimerWsClient(accessToken: 'token-a', autoConnect: false);
      final client2 = TimerWsClient(accessToken: 'token-b', autoConnect: false);
      addTearDown(client1.dispose);
      addTearDown(client2.dispose);

      expect(client1.token, 'token-a');
      expect(client2.token, 'token-b');
    });
  });

  // ============================================================
  // TimerWsClient dispose — 리소스 해제
  // ============================================================
  group('TimerWsClient dispose', () {
    test('dispose 후 messageStream이 닫힌다', () async {
      final client = TimerWsClient(
        accessToken: 'test-token',
        autoConnect: false,
      );

      bool streamDone = false;
      client.messageStream.listen((_) {}, onDone: () => streamDone = true);

      client.dispose();
      await Future.delayed(Duration.zero);

      expect(streamDone, isTrue);
    });

    test('disconnect 후 isConnected가 false이다', () {
      final client = TimerWsClient(
        accessToken: 'test-token',
        autoConnect: false,
      );
      addTearDown(client.dispose);

      client.disconnect();

      expect(client.isConnected, isFalse);
    });

    test('autoConnect: false면 초기 상태에서 연결되지 않는다', () {
      final client = TimerWsClient(
        accessToken: 'test-token',
        autoConnect: false,
      );
      addTearDown(client.dispose);

      expect(client.isConnected, isFalse);
    });
  });

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
    TimerWsClient createClient() => TimerWsClient(
      accessToken: 'jwt',
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

      for (var i = 0; i < 10; i++) {
        channels.last.serverClose(1006);
        await tester.pump(const Duration(seconds: 30));
      }
      expect(channels, hasLength(11));

      client.dispose();
    });

    testWidgets('connected를 받으면 백오프가 처음으로 돌아간다', (tester) async {
      final client = createClient();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 500));
      channels.last.serverClose(1006);
      await tester.pump(const Duration(seconds: 1));
      expect(channels, hasLength(3));

      channels.last.serverSend(_connectedJson);
      await tester.pump();
      channels.last.serverClose(1001);
      await tester.pump(const Duration(milliseconds: 500));
      expect(channels, hasLength(4));

      client.dispose();
    });

    testWidgets('재접속 후 서버의 자동 sync_result가 같은 스트림으로 전달된다', (tester) async {
      final client = createClient();
      final events = <TimerWsEvent>[];
      final sub = client.messageStream.listen(events.add);

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 500));

      channels.last
        ..serverSend(_connectedJson)
        ..serverSend(
          jsonEncode({
            'type': 'timer.sync_result',
            'payload': {
              'timers': [
                {
                  'id': 't1',
                  'allocated_duration': 3600,
                  'elapsed_time': 0,
                  'status': 'RUNNING',
                  'created_at': '2026-01-01T00:00:00Z',
                  'updated_at': '2026-01-01T00:00:00Z',
                },
              ],
              'count': 1,
            },
          }),
        );
      await tester.pump();

      expect(events.whereType<TimerWsConnected>(), hasLength(1));
      final sync = events.whereType<TimerWsSyncResult>().single;
      expect(sync.timers.single.id, 't1');
      expect(client.isConnected, isTrue);

      await sub.cancel();
      client.dispose();
    });

    testWidgets('인증 실패(1008)면 재접속하지 않고 AUTH_FAILED를 알린다', (tester) async {
      final client = createClient();
      final events = <TimerWsEvent>[];
      final sub = client.messageStream.listen(events.add);

      channels.last.serverClose(1008);
      await tester.pump(const Duration(seconds: 60));

      expect(channels, hasLength(1));
      expect(
        events.whereType<TimerWsError>().map((e) => e.code),
        contains('AUTH_FAILED'),
      );

      await sub.cancel();
      client.dispose();
    });

    testWidgets('disconnect하면 채널을 닫고 재접속하지 않는다', (tester) async {
      final client = createClient();
      final channel = channels.last;

      client.disconnect();
      channel.serverClose(1000);
      await tester.pump(const Duration(seconds: 60));

      expect(channel.sink.closed, isTrue);
      expect(channels, hasLength(1));

      client.dispose();
    });

    testWidgets('재접속 대기 중 disconnect하면 예약된 재접속이 취소된다', (tester) async {
      final client = createClient();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 100));
      client.disconnect();
      await tester.pump(const Duration(seconds: 60));

      expect(channels, hasLength(1));

      client.dispose();
    });

    testWidgets('재접속 대기 중 dispose하면 예약된 재접속이 취소된다', (tester) async {
      final client = createClient();

      channels.last.serverClose(1006);
      await tester.pump(const Duration(milliseconds: 100));
      client.dispose();
      await tester.pump(const Duration(seconds: 60));

      expect(channels, hasLength(1));
    });
  });
}

const _connectedJson = '{"type":"connected","payload":{"user_id":"u1"}}';

class _FixedRandom extends Fake implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;
}

class _FakeSink extends Fake implements WebSocketSink {
  bool closed = false;

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
