import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_session.dart';

void main() {
  late DateTime now;
  late int widgetResets;
  late TurnstileSession session;

  setUp(() {
    now = DateTime.utc(2026, 11, 17, 12);
    widgetResets = 0;
    session = TurnstileSession(
      resetWidget: () => widgetResets++,
      now: () => now,
    );
  });

  tearDown(() => session.dispose());

  test('처음에는 확인 중이고, 받은 토큰을 한 번만 준다', () async {
    expect(session.status.value, TurnstileStatus.verifying);

    session.onToken('t1');
    expect(session.status.value, TurnstileStatus.ready);
    expect(await session.nextToken(), 't1');

    final next = session.nextToken();
    session.onToken('t2');
    expect(await next, 't2');
  });

  test('기다리는 요청에는 들어오는 차례로 토큰을 준다', () async {
    final a = session.nextToken();
    final b = session.nextToken();

    session.onToken('t1');
    session.onToken('t2');

    expect(await a, 't1');
    expect(await b, 't2');
  });

  group('만료(expired-callback, refresh-expired: auto)', () {
    test('들고 있던 토큰을 버리고 확인 중이 되며 위젯을 다시 그리지 않는다', () async {
      session.onToken('t1');

      session.onExpired();

      expect(session.status.value, TurnstileStatus.verifying);
      expect(widgetResets, 0, reason: '위젯이 스스로 새 토큰을 받는다');
      final next = session.nextToken();
      session.onToken('t2');
      expect(await next, 't2');
    });

    test('만료 알림이 오지 않았어도 받은 지 300초가 다 되어 가는 토큰은 주지 않고 다시 확인한다', () async {
      session.onToken('t1');
      now = now.add(
        TurnstileSession.tokenLifetime - TurnstileSession.expiryMargin,
      );

      final next = session.nextToken();
      await pumpEventQueue();

      expect(widgetResets, 1);
      expect(session.status.value, TurnstileStatus.verifying);
      session.onToken('t2');
      expect(await next, 't2');
    });

    test('아직 이른 토큰은 그대로 준다', () async {
      session.onToken('t1');
      now = now.add(
        TurnstileSession.tokenLifetime -
            TurnstileSession.expiryMargin -
            const Duration(seconds: 1),
      );

      expect(await session.nextToken(), 't1');
      expect(widgetResets, 0);
    });
  });

  test(
    '시간 안에 풀지 못하면(timeout-callback) 위젯이 스스로 다시 시작하므로 확인 중이고 기다리던 요청은 실패하지 않는다',
    () async {
      final next = session.nextToken();
      var failed = false;
      unawaited(next.then((_) {}, onError: (_) => failed = true));

      session.onBeforeInteractive();
      session.onTimeout();
      await pumpEventQueue();

      expect(session.status.value, TurnstileStatus.verifying);
      expect(failed, isFalse);
      expect(widgetResets, 0);
      session.onToken('t1');
      expect(await next, 't1');
    },
  );

  group('오류(error-callback, retry: auto)', () {
    for (final code in ['110600', '110620', '200500', '300010', '600010']) {
      test('다시 시도하는 오류($code)는 확인 중으로 두고 기다리던 요청을 그대로 둔다', () async {
        final next = session.nextToken();
        var failed = false;
        unawaited(next.then((_) {}, onError: (_) => failed = true));

        expect(session.onError(code), isTrue, reason: '처리했다고 돌려준다');
        await pumpEventQueue();

        expect(session.status.value, TurnstileStatus.verifying);
        expect(failed, isFalse);
        session.onToken('t1');
        expect(await next, 't1');
      });
    }

    for (final code in [
      '110100',
      '110110',
      '110200',
      '200100',
      '400020',
      '400021',
      '400070',
    ]) {
      test('다시 해도 안 되는 오류($code)는 쓸 수 없음이 되고 기다리던 요청을 끝낸다', () async {
        final next = session.nextToken();

        expect(session.onError(code), isTrue);

        expect(session.status.value, TurnstileStatus.unavailable);
        await expectLater(
          next,
          throwsA(
            isA<TurnstileException>().having(
              (e) => e.status,
              'status',
              TurnstileStatus.unavailable,
            ),
          ),
        );
        await expectLater(
          session.nextToken(),
          throwsA(isA<TurnstileException>()),
        );
      });
    }

    test('목록에 없는 코드는 다시 시도하는 오류로 본다', () {
      expect(session.onError('102001'), isTrue);
      expect(session.status.value, TurnstileStatus.verifying);
    });

    test('오류 뒤에 들고 있던 토큰은 버린다', () async {
      session.onToken('t1');
      session.onError('300010');

      final next = session.nextToken();
      session.onToken('t2');
      expect(await next, 't2');
    });
  });

  test('지원하지 않는 브라우저(unsupported-callback)면 쓸 수 없음이고 기다리던 요청을 끝낸다', () async {
    final next = session.nextToken();

    session.onUnsupported();

    expect(session.status.value, TurnstileStatus.unavailable);
    await expectLater(next, throwsA(isA<TurnstileException>()));
  });

  test(
    '상자 안에서 할 일이 생기면(before-interactive) 그 상태가 되고, 끝나면(after-interactive) 확인 중으로 돌아간다',
    () async {
      final next = session.nextToken();

      session.onBeforeInteractive();
      expect(session.status.value, TurnstileStatus.interactive);

      session.onAfterInteractive();
      expect(session.status.value, TurnstileStatus.verifying);

      session.onToken('t1');
      expect(session.status.value, TurnstileStatus.ready);
      expect(await next, 't1');
    },
  );

  test('토큰이 먼저 오고 상호작용 끝 알림이 늦게 와도 확인됨에 머문다', () {
    session.onBeforeInteractive();
    session.onToken('t1');
    session.onAfterInteractive();

    expect(session.status.value, TurnstileStatus.ready);
  });

  test('다시 확인(reset)은 토큰을 버리고 위젯을 다시 확인하게 한다', () async {
    session.onToken('t1');

    session.reset();

    expect(widgetResets, 1);
    expect(session.status.value, TurnstileStatus.verifying);
    final next = session.nextToken();
    session.onToken('t2');
    expect(await next, 't2');
  });

  test('쓸 수 없음에서 토큰을 달라면 바로 실패하고, 다시 확인하면 다시 기다린다', () async {
    session.fail(TurnstileStatus.unavailable);

    await expectLater(session.nextToken(), throwsA(isA<TurnstileException>()));

    session.reset();
    expect(session.status.value, TurnstileStatus.verifying);
    final next = session.nextToken();
    session.onToken('t1');
    expect(await next, 't1');
  });

  test('닫으면 기다리던 요청을 끝내고 그 뒤의 알림은 무시한다', () async {
    final local = TurnstileSession(resetWidget: () {});
    final next = local.nextToken();

    local.dispose();

    await expectLater(next, throwsA(isA<TurnstileException>()));
    local.onToken('t1');
    await expectLater(local.nextToken(), throwsA(isA<TurnstileException>()));
  });
}
