import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';

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
}
