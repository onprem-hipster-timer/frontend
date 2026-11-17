import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_field.dart';

import '../../helpers/fake_turnstile.dart';

void main() {
  group('send', () {
    test('요청마다 새 토큰을 쓰고 응답 뒤에 다시 확인한다', () async {
      final turnstile = FakeTurnstile();
      final sent = <String>[];

      await turnstile.send((token) async => sent.add(token));
      await turnstile.send((token) async => sent.add(token));

      expect(sent, ['token-1', 'token-2']);
      expect(turnstile.resets, 2);
    });

    test('거절·실패한 요청 뒤에도 다시 확인하고 다음 요청은 새 토큰이다', () async {
      final turnstile = FakeTurnstile();
      final sent = <String>[];

      await expectLater(
        turnstile.send<void>((token) async {
          sent.add(token);
          throw StateError('403');
        }),
        throwsStateError,
      );
      await turnstile.send((token) async => sent.add(token));

      expect(sent, ['token-1', 'token-2']);
      expect(turnstile.resets, 2);
    });

    test('앞 요청이 끝나기 전의 요청은 다시 확인한 뒤의 토큰을 기다린다', () async {
      final turnstile = FakeTurnstile();
      final sent = <String>[];
      final first = Completer<void>();

      final a = turnstile.send((token) async {
        sent.add(token);
        await first.future;
      });
      final b = turnstile.send((token) async => sent.add(token));
      await pumpEventQueue();
      expect(sent, ['token-1']);

      first.complete();
      await Future.wait([a, b]);
      expect(sent, ['token-1', 'token-2']);
    });

    test('토큰을 받지 못하면 요청을 보내지 않는다', () async {
      final turnstile = FakeTurnstile(initial: TurnstileStatus.unavailable);
      var sent = 0;

      await expectLater(
        turnstile.send((token) async => sent++),
        throwsA(isA<TurnstileException>()),
      );
      expect(sent, 0);
    });
  });

  group('TurnstileField', () {
    Future<void> pumpField(WidgetTester tester, FakeTurnstile turnstile) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TurnstileField(controller: turnstile)),
          ),
        );

    testWidgets('확인 중·확인됨이면 상자만 보인다', (tester) async {
      final turnstile = FakeTurnstile(initial: TurnstileStatus.verifying);
      await pumpField(tester, turnstile);

      expect(find.bySemanticsLabel('사람인지 확인하는 상자'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('불러오지 못하면 빈 상자 대신 알리고 다시 불러온다', (tester) async {
      final turnstile = FakeTurnstile(initial: TurnstileStatus.unavailable);
      await pumpField(tester, turnstile);

      expect(find.bySemanticsLabel('사람인지 확인하는 상자'), findsNothing);
      expect(find.textContaining('확인 상자를 불러오지 못했습니다'), findsOneWidget);

      await tester.tap(find.text('다시 불러오기'));
      await tester.pump();
      expect(turnstile.resets, 1);
      expect(find.bySemanticsLabel('사람인지 확인하는 상자'), findsOneWidget);
    });

    testWidgets('확인하지 못하면 알리고 다시 확인한다', (tester) async {
      final turnstile = FakeTurnstile(initial: TurnstileStatus.failed);
      await pumpField(tester, turnstile);

      expect(find.text('사람인지 확인하지 못했습니다.'), findsOneWidget);
      await tester.tap(find.text('다시 확인'));
      expect(turnstile.resets, 1);
    });

    testWidgets('상자 안에서 할 일이 생기면 상자를 보이게 굴리고 눌러 달라고 한 줄 적으며, 끝나면 그 줄을 지운다', (
      tester,
    ) async {
      final turnstile = FakeTurnstile(initial: TurnstileStatus.verifying);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 2000),
                  TurnstileField(controller: turnstile),
                ],
              ),
            ),
          ),
        ),
      );
      final box = find.bySemanticsLabel('사람인지 확인하는 상자');
      expect(tester.getTopLeft(box).dy, greaterThan(600));
      expect(find.text('확인 상자를 눌러 주세요'), findsNothing);

      turnstile.beginInteractive();
      await tester.pumpAndSettle();

      expect(find.text('확인 상자를 눌러 주세요'), findsOneWidget);
      final rect = tester.getRect(box);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(600));
      expect(find.byType(TextButton), findsNothing, reason: '다시 할 단추는 없다');

      turnstile.endInteractive();
      await tester.pumpAndSettle();
      expect(find.text('확인 상자를 눌러 주세요'), findsNothing);
    });

    testWidgets('애니메이션을 줄였으면 움직임 없이 상자로 간다', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final turnstile = FakeTurnstile(initial: TurnstileStatus.verifying);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 2000),
                  TurnstileField(controller: turnstile),
                ],
              ),
            ),
          ),
        ),
      );

      turnstile.beginInteractive();
      await tester.pump();
      await tester.pump();

      final rect = tester.getRect(find.bySemanticsLabel('사람인지 확인하는 상자'));
      expect(rect.bottom, lessThanOrEqualTo(600));
    });
  });
}
