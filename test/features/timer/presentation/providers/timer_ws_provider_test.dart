import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';

void main() {
  // ============================================================
  // 토큰 삽입 검증
  // ============================================================
  group('토큰 삽입', () {
    test('토큰이 있으면 클라이언트가 생성된다', () {
      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            return TimerWsClient(accessToken: 'jwt-123', autoConnect: false);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(timerWsClientProvider), isNotNull);
    });

    test('생성된 클라이언트에 전달된 토큰이 저장되어 있다', () {
      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            return TimerWsClient(
              accessToken: 'my-access-token',
              autoConnect: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(timerWsClientProvider)!;
      expect(client.token, 'my-access-token');
    });

    test('토큰이 Sec-WebSocket-Protocol 형식으로 사용된다', () {
      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            return TimerWsClient(
              accessToken: 'eyJhbG.payload.sig',
              autoConnect: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(timerWsClientProvider)!;
      final protocols = TimerWsClient.authProtocols(client.token);
      expect(protocols.single, 'authorization.bearer.eyJhbG.payload.sig');
    });
  });

  // ============================================================
  // 토큰 없음 — 클라이언트 미생성
  // ============================================================
  group('토큰 없으면 클라이언트 미생성', () {
    test('토큰이 null이면 클라이언트가 null이다', () {
      final container = ProviderContainer(
        overrides: [timerWsClientProvider.overrideWith((ref) => null)],
      );
      addTearDown(container.dispose);

      expect(container.read(timerWsClientProvider), isNull);
    });

    test('토큰이 빈 문자열이면 클라이언트가 null이다', () {
      final token = '';

      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            if (token.isEmpty) return null;
            return TimerWsClient(accessToken: token, autoConnect: false);
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(timerWsClientProvider), isNull);
    });
  });

  // ============================================================
  // 로그아웃 — 토큰 제거 시 WS 닫힘
  // ============================================================
  group('로그아웃 시 WS 닫힘', () {
    test('토큰이 null로 변경되면 클라이언트가 null이 된다', () async {
      String? token = 'valid-token';

      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            if (token == null || token.isEmpty) return null;
            final client = TimerWsClient(
              accessToken: token,
              autoConnect: false,
            );
            ref.onDispose(() => client.dispose());
            return client;
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(timerWsClientProvider), isNotNull);

      token = null;
      container.invalidate(timerWsClientProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(timerWsClientProvider), isNull);
    });

    test('토큰 제거 시 기존 클라이언트가 dispose된다 (스트림 종료)', () async {
      String? token = 'valid-token';

      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            if (token == null || token.isEmpty) return null;
            final client = TimerWsClient(
              accessToken: token,
              autoConnect: false,
            );
            ref.onDispose(() => client.dispose());
            return client;
          }),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(timerWsClientProvider)!;

      bool streamClosed = false;
      client.messageStream.listen((_) {}, onDone: () => streamClosed = true);

      token = null;
      container.invalidate(timerWsClientProvider);
      await Future.delayed(Duration.zero);

      expect(streamClosed, isTrue);
    });

    test('토큰이 빈 문자열로 변경되어도 클라이언트가 dispose된다', () async {
      String? token = 'valid-token';

      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            if (token == null || token.isEmpty) return null;
            final client = TimerWsClient(
              accessToken: token,
              autoConnect: false,
            );
            ref.onDispose(() => client.dispose());
            return client;
          }),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(timerWsClientProvider)!;

      bool streamClosed = false;
      client.messageStream.listen((_) {}, onDone: () => streamClosed = true);

      token = '';
      container.invalidate(timerWsClientProvider);
      await Future.delayed(Duration.zero);

      expect(container.read(timerWsClientProvider), isNull);
      expect(streamClosed, isTrue);
    });
  });

  // ============================================================
  // 토큰 갱신 — 새 토큰으로 교체
  // ============================================================
  group('토큰 갱신', () {
    test('토큰이 변경되면 새 클라이언트가 생성된다', () async {
      var token = 'old-token';

      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            if (token.isEmpty) return null;
            final client = TimerWsClient(
              accessToken: token,
              autoConnect: false,
            );
            ref.onDispose(() => client.dispose());
            return client;
          }),
        ],
      );
      addTearDown(container.dispose);

      final oldClient = container.read(timerWsClientProvider)!;
      expect(oldClient.token, 'old-token');

      token = 'new-token';
      container.invalidate(timerWsClientProvider);
      await Future.delayed(Duration.zero);

      final newClient = container.read(timerWsClientProvider)!;
      expect(newClient.token, 'new-token');
      expect(newClient, isNot(same(oldClient)));
    });

    test('토큰 변경 시 이전 클라이언트가 dispose된다 (스트림 종료)', () async {
      var token = 'token-v1';

      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            if (token.isEmpty) return null;
            final client = TimerWsClient(
              accessToken: token,
              autoConnect: false,
            );
            ref.onDispose(() => client.dispose());
            return client;
          }),
        ],
      );
      addTearDown(container.dispose);

      final oldClient = container.read(timerWsClientProvider)!;

      bool oldStreamClosed = false;
      oldClient.messageStream.listen(
        (_) {},
        onDone: () => oldStreamClosed = true,
      );

      token = 'token-v2';
      container.invalidate(timerWsClientProvider);
      await Future.delayed(Duration.zero);

      expect(oldStreamClosed, isTrue);
    });

    test('토큰 변경 후 새 클라이언트의 스트림은 열려 있다', () async {
      var token = 'token-v1';

      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            if (token.isEmpty) return null;
            final client = TimerWsClient(
              accessToken: token,
              autoConnect: false,
            );
            ref.onDispose(() => client.dispose());
            return client;
          }),
        ],
      );
      addTearDown(container.dispose);

      token = 'token-v2';
      container.invalidate(timerWsClientProvider);
      await Future.delayed(Duration.zero);

      final newClient = container.read(timerWsClientProvider)!;

      bool newStreamClosed = false;
      newClient.messageStream.listen(
        (_) {},
        onDone: () => newStreamClosed = true,
      );

      await Future.delayed(Duration.zero);
      expect(newStreamClosed, isFalse);
    });
  });

  // ============================================================
  // 컨테이너 dispose — 전체 정리
  // ============================================================
  group('컨테이너 dispose', () {
    test('컨테이너 dispose 시 활성 클라이언트가 dispose된다', () async {
      final container = ProviderContainer(
        overrides: [
          timerWsClientProvider.overrideWith((ref) {
            final client = TimerWsClient(
              accessToken: 'active-token',
              autoConnect: false,
            );
            ref.onDispose(() => client.dispose());
            return client;
          }),
        ],
      );

      final client = container.read(timerWsClientProvider)!;

      bool streamClosed = false;
      client.messageStream.listen((_) {}, onDone: () => streamClosed = true);

      container.dispose();
      await Future.delayed(Duration.zero);

      expect(streamClosed, isTrue);
    });
  });
}
