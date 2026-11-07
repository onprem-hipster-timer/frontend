import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../helpers/fake_ws_server.dart';

void main() {
  // ============================================================
  // TimerWsClient.wsUrl — 정적 메서드
  // ============================================================
  group('TimerWsClient.wsUrl', () {
    test('https를 wss로 변환한다', () {
      expect(
        TimerWsClient.wsUrl('https://api.momeet.date', '/v1/ws/timers'),
        'wss://api.momeet.date/v1/ws/timers',
      );
    });

    test('http를 ws로 변환한다', () {
      expect(
        TimerWsClient.wsUrl('http://localhost:2614', '/v1/ws/timers'),
        'ws://localhost:2614/v1/ws/timers',
      );
    });

    test('기본 포트(443)는 생략된다', () {
      expect(
        TimerWsClient.wsUrl('https://api.example.com:443', '/v1/ws/timers'),
        'wss://api.example.com/v1/ws/timers',
      );
    });

    test('비표준 포트를 유지한다', () {
      expect(
        TimerWsClient.wsUrl('http://localhost:8080', '/v1/ws/timers'),
        'ws://localhost:8080/v1/ws/timers',
      );
    });

    test('cloudflare 모드 경로(/realtime/ws)를 붙인다', () {
      expect(
        TimerWsClient.wsUrl('https://api.momeet.date', '/realtime/ws'),
        'wss://api.momeet.date/realtime/ws',
      );
    });

    test('baseUrl에 기존 경로가 있어도 소켓 경로만 사용한다', () {
      final url = TimerWsClient.wsUrl(
        'https://api.momeet.date/some/path',
        '/v1/ws/timers',
      );
      expect(url, 'wss://api.momeet.date/v1/ws/timers');
    });

    test('baseUrl에 trailing slash가 있어도 정상 동작한다', () {
      final url = TimerWsClient.wsUrl(
        'https://api.momeet.date/',
        '/v1/ws/timers',
      );
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
  // TimerWsClient — 로컬 WebSocket 서버
  // ============================================================
  group('TimerWsClient 연결', () {
    late FakeWsServer server;
    late String token;
    late List<TimerWsEvent> events;

    setUp(() async {
      server = await FakeWsServer.start();
      token = 'jwt-1';
      events = [];
    });
    tearDown(() => server.close());

    TimerWsClient connect({
      Future<String?> Function()? refreshAccessToken,
      Duration pingInterval = const Duration(seconds: 45),
    }) {
      final client = TimerWsClient(
        accessToken: () async => token,
        refreshAccessToken:
            refreshAccessToken ?? () async => token = 'jwt-refreshed',
        pingInterval: pingInterval,
      );
      final subscription = client.messageStream.listen(events.add);
      addTearDown(() async {
        await subscription.cancel();
        client.dispose();
      });
      return client;
    }

    void send(Map<String, Object?> message) =>
        server.sockets.last.add(jsonEncode(message));

    test('기본 경로(/v1/ws/timers)로 연결한다', () async {
      connect();
      await server.waitForConnections(1);

      expect(server.paths.single, '/v1/ws/timers');
      expect(server.protocols.single, 'authorization.bearer.jwt-1');
    });

    test('끊겨서 다시 연결할 때 JWT를 새로 받는다', () async {
      var issued = 0;
      final client = TimerWsClient(
        accessToken: () async => 'jwt-${++issued}',
        refreshAccessToken: () async => null,
      );
      addTearDown(client.dispose);

      await server.waitForConnections(1);
      // 서버 내부 오류(1011)로 끊기면 1초 뒤 다시 연결한다
      await server.sockets.single.close(1011, 'test');
      await server.waitForConnections(2, timeout: const Duration(seconds: 3));

      expect(server.protocols, [
        'authorization.bearer.jwt-1',
        'authorization.bearer.jwt-2',
      ]);
    });

    test('JWT가 없으면(로그아웃) 연결하지 않는다', () async {
      final client = TimerWsClient(
        accessToken: () async => null,
        refreshAccessToken: () async => null,
      );
      addTearDown(client.dispose);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(server.protocols, isEmpty);
    });

    test('connected와 타이머 이벤트를 내보내고 같은 id는 한 번만 내보낸다', () async {
      connect();
      await server.waitForConnections(1);

      send(_connected);
      send(_event('m1'));
      send(_event('m1'));
      send(_event('m2'));
      await _eventually(() => events.length >= 3);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.first, isA<TimerWsConnected>());
      expect(events.skip(1).cast<TimerWsTimerEvent>().map((e) => e.id), [
        'm1',
        'm2',
      ]);
    });

    test('pong 등 봉투가 아닌 메시지는 버린다', () async {
      connect();
      await server.waitForConnections(1);

      server.sockets.last
        ..add('pong')
        ..add('{"unexpected":true}');
      send(_event('m1'));
      await _eventually(() => events.isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.single, isA<TimerWsTimerEvent>());
    });

    test('주기적으로 문자열 ping을 보낸다', () async {
      connect(pingInterval: const Duration(milliseconds: 50));
      await server.waitForConnections(1);

      await _eventually(
        () => server.received.where((m) => m == 'ping').length >= 2,
      );
    });

    test('4000(소켓 수명 만료)이면 바로 다시 연결한다', () async {
      connect();
      await server.waitForConnections(1);

      await server.sockets.single.close(4000, 'expired');

      // 백오프(최소 1초) 없이 다시 연결한다
      await server.waitForConnections(
        2,
        timeout: const Duration(milliseconds: 500),
      );
    });

    test('1008(인증 실패)이면 JWT를 새로 받아 다시 연결한다', () async {
      connect();
      await server.waitForConnections(1);

      await server.sockets.single.close(1008, 'invalid token');
      await server.waitForConnections(
        2,
        timeout: const Duration(milliseconds: 500),
      );

      expect(server.protocols.last, 'authorization.bearer.jwt-refreshed');
    });

    test('새 JWT도 1008이면 다시 연결하지 않고 AUTH_FAILED를 알린다', () async {
      connect();
      await server.waitForConnections(1);
      await server.sockets.last.close(1008, 'invalid token');
      await server.waitForConnections(2);

      await server.sockets.last.close(1008, 'invalid token');
      await _eventually(() => events.whereType<TimerWsError>().isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(server.protocols, hasLength(2));
      expect(events.whereType<TimerWsError>().single.code, 'AUTH_FAILED');
    });

    test('1008 뒤 세션이 끝나 JWT를 받지 못하면 다시 연결하지 않는다', () async {
      connect(refreshAccessToken: () async => null);
      await server.waitForConnections(1);

      await server.sockets.single.close(1008, 'invalid token');
      await _eventually(() => events.whereType<TimerWsError>().isNotEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      expect(server.protocols, hasLength(1));
      expect(events.whereType<TimerWsError>().single.code, 'AUTH_FAILED');
    });
  });

  // ============================================================
  // TimerWsClient dispose — 리소스 해제
  // ============================================================
  group('TimerWsClient dispose', () {
    TimerWsClient idle() => TimerWsClient(
      accessToken: () async => 'test-token',
      refreshAccessToken: () async => 'test-token',
      autoConnect: false,
    );

    test('dispose 후 messageStream이 닫힌다', () async {
      final client = idle();

      bool streamDone = false;
      client.messageStream.listen((_) {}, onDone: () => streamDone = true);

      client.dispose();
      await Future.delayed(Duration.zero);

      expect(streamDone, isTrue);
    });

    test('disconnect 후 isConnected가 false이다', () {
      final client = idle();
      addTearDown(client.dispose);

      client.disconnect();

      expect(client.isConnected, isFalse);
    });

    test('autoConnect: false면 초기 상태에서 연결되지 않는다', () {
      final client = idle();
      addTearDown(client.dispose);

      expect(client.isConnected, isFalse);
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

Map<String, Object?> _event(String id) => {
  'id': id,
  'type': 'timer.deleted',
  'from_user': 'user-1',
  'timestamp': '2026-11-06T10:30:00+0000',
  'payload': {
    'action': 'delete',
    'actor_name': null,
    'timer': null,
    'timer_id': 't1',
  },
};

/// [condition]이 참이 될 때까지 기다린다.
Future<void> _eventually(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('조건을 기다리다 시간 초과');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
