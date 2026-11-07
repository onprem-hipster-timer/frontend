import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../helpers/fake_ws_server.dart';

void main() {
  late FakeWsServer server;
  late String token;
  late List<TimerWsEvent> events;

  setUp(() async {
    server = await FakeWsServer.start();
    token = 'jwt-1';
    events = [];
  });
  tearDown(() => server.close());

  TimerWsClient connect({Future<String?> Function()? refreshAccessToken}) {
    final client = TimerWsClient(
      accessToken: () async => token,
      refreshAccessToken:
          refreshAccessToken ?? () async => token = 'jwt-refreshed',
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

  test('깨진 JSON이 와도 소켓은 살아 있고 다음 이벤트를 받는다', () async {
    connect();
    await server.waitForConnections(1);

    server.sockets.last.add('{"id": "broken"');
    send(_event('m1'));
    await _eventually(() => events.isNotEmpty);

    expect(events.single, isA<TimerWsTimerEvent>());
    expect(server.sockets, hasLength(1));
  });

  test('모르는 type의 봉투는 버리고 그 뒤 이벤트는 받는다', () async {
    connect();
    await server.waitForConnections(1);

    send({..._event('m0'), 'type': 'timer.renamed'});
    send(_event('m1'));
    await _eventually(() => events.isNotEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events.map((e) => (e as TimerWsTimerEvent).id), ['m1']);
  });

  test('connected보다 먼저 온 이벤트도 내보낸다', () async {
    connect();
    await server.waitForConnections(1);

    send(_event('m1'));
    send(_connected);
    await _eventually(() => events.length >= 2);

    expect(events.first, isA<TimerWsTimerEvent>());
    expect(events.last, isA<TimerWsConnected>());
  });

  test('재연결 전에 본 id는 재연결 뒤에 다시 와도 한 번만 내보낸다', () async {
    connect();
    await server.waitForConnections(1);

    send(_event('m1'));
    await _eventually(() => events.length == 1);

    await server.sockets.single.close(4000, 'expired');
    await server.waitForConnections(2);
    send(_event('m1'));
    send(_event('m2'));
    await _eventually(() => events.length >= 2);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(events.whereType<TimerWsTimerEvent>().map((e) => e.id), [
      'm1',
      'm2',
    ]);
  });

  test('1008 뒤 새 JWT로 연결이 되면 다음 1008에서 다시 한 번 갱신한다', () async {
    var refreshed = 0;
    connect(refreshAccessToken: () async => token = 'jwt-r${++refreshed}');
    await server.waitForConnections(1);

    await server.sockets.last.close(1008, 'expired');
    await server.waitForConnections(2);
    send(_connected);
    await _eventually(() => events.whereType<TimerWsConnected>().isNotEmpty);

    await server.sockets.last.close(1008, 'expired again');
    await server.waitForConnections(3, timeout: const Duration(seconds: 2));

    expect(refreshed, 2);
    expect(events.whereType<TimerWsError>(), isEmpty);
  });

  test('AUTH_FAILED 뒤 reconnectNow하면 새 JWT로 다시 연결을 시도한다', () async {
    final client = connect(refreshAccessToken: () async => null);
    await server.waitForConnections(1);
    await server.sockets.single.close(1008, 'invalid');
    await _eventually(() => events.whereType<TimerWsError>().isNotEmpty);

    token = 'jwt-after-login';
    client.reconnectNow();
    await server.waitForConnections(2, timeout: const Duration(seconds: 1));

    expect(server.protocols.last, 'authorization.bearer.jwt-after-login');
  });

  test('4000이 연달아 와도 매번 바로 다시 연결한다', () async {
    connect();
    await server.waitForConnections(1);

    for (var i = 1; i <= 3; i++) {
      await server.sockets.last.close(4000, 'expired');
      await server.waitForConnections(
        i + 1,
        timeout: const Duration(milliseconds: 500),
      );
    }

    expect(server.sockets, hasLength(4));
  });

  test('재연결한 뒤에도 ping을 계속 보낸다', () async {
    final client = TimerWsClient(
      accessToken: () async => token,
      refreshAccessToken: () async => token,
      pingInterval: const Duration(milliseconds: 50),
    );
    addTearDown(client.dispose);
    await server.waitForConnections(1);
    await _eventually(() => server.received.contains('ping'));

    await server.sockets.single.close(4000, 'expired');
    await server.waitForConnections(2);
    final before = server.received.where((m) => m == 'ping').length;

    await _eventually(
      () => server.received.where((m) => m == 'ping').length > before,
    );
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
