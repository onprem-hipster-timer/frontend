import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';

import '../../../../helpers/fake_ws_server.dart';
import '../../../../helpers/kratos_mocks.dart';

void main() {
  // 포그라운드 복귀 감지(AppLifecycleListener)에 바인딩이 필요하다.
  // 테스트 바인딩이 막는 HttpClient는 로컬 소켓 서버에 붙도록 되돌린다.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  late FakeWsServer server;
  late KratosTestHarness harness;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    server = await FakeWsServer.start();
    harness = await KratosTestHarness.create();
  });

  tearDown(() => server.close());

  Future<ProviderContainer> boot() async {
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    container.read(authProvider);
    await pumpEventQueue();
    return container;
  }

  test('로그인 상태면 최신 JWT로 연결한다', () async {
    final container = await boot();

    expect(container.read(timerWsClientProvider), isNotNull);
    await server.waitForConnections(1);
    expect(
      server.protocols.single,
      'authorization.bearer.${harness.accessToken}',
    );
  });

  test('JWT가 갱신돼도 클라이언트와 연결을 그대로 쓴다', () async {
    final container = await boot();
    final client = container.read(timerWsClientProvider);
    await server.waitForConnections(1);

    harness.accessToken = testJwt();
    await container.read(authProvider.notifier).refreshAccessToken();
    await pumpEventQueue();

    expect(container.read(timerWsClientProvider), same(client));
    expect(server.protocols, hasLength(1));
  });

  test('로그아웃하면 클라이언트가 사라지고 스트림이 닫힌다', () async {
    when(() => harness.kratos.logout(any())).thenAnswer((_) async {});
    final container = await boot();
    final client = container.read(timerWsClientProvider)!;
    var closed = false;
    client.messageStream.listen((_) {}, onDone: () => closed = true);
    await server.waitForConnections(1);

    await container.read(authProvider.notifier).signOut();
    expect(container.read(timerWsClientProvider), isNull);
    await pumpEventQueue();

    expect(closed, isTrue);
  });

  test('앱이 포그라운드로 돌아오면 끊긴 연결을 백오프 없이 다시 연다', () async {
    final container = await boot();
    container.read(timerWsClientProvider);
    await server.waitForConnections(1);

    // 1011로 끊기면 0.5~1초 뒤에 다시 연결할 예정이다
    await server.sockets.single.close(1011, 'test');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    WidgetsBinding.instance
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await server.waitForConnections(
      2,
      timeout: const Duration(milliseconds: 400),
    );
  });

  test('미인증이면 클라이언트가 없다', () async {
    harness = await KratosTestHarness.create(authenticated: false);
    final container = await boot();

    expect(container.read(timerWsClientProvider), isNull);
  });
}
