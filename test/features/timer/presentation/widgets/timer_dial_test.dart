import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('dialFaceFor', () {
    for (final (minutes, face) in [
      (25, 60),
      (60, 60),
      (61, 120),
      (90, 120),
      (150, 180),
    ]) {
      test('$minutes분은 $face분 다이얼', () {
        expect(
          dialFaceFor(Duration(minutes: minutes)),
          Duration(minutes: face),
        );
      });
    }
  });

  group('dialDurationAt', () {
    const size = 200.0;
    const face = dialFaceDuration;

    test('3시·6시·9시는 15·30·45분', () {
      expect(dialDurationAt(const Offset(190, 100), size, face), 15.minutes);
      expect(dialDurationAt(const Offset(100, 190), size, face), 30.minutes);
      expect(dialDurationAt(const Offset(10, 100), size, face), 45.minutes);
    });

    test('정확히 12시는 1분, 12시 바로 앞은 60분', () {
      expect(dialDurationAt(const Offset(100, 10), size, face), 1.minutes);
      expect(dialDurationAt(const Offset(99, 10), size, face), 60.minutes);
    });

    test('중심 가까이(한 변의 5% 안쪽)는 null', () {
      expect(dialDurationAt(const Offset(100, 100), size, face), isNull);
      expect(dialDurationAt(const Offset(109, 100), size, face), isNull);
    });

    test('120분 다이얼의 3시는 30분', () {
      expect(
        dialDurationAt(const Offset(190, 100), size, 120.minutes),
        30.minutes,
      );
    });
  });

  group('TimerDial', () {
    Future<void> pumpDial(
      WidgetTester tester, {
      double size = 200,
      ValueChanged<Duration>? onChanged,
    }) async {
      await tester.pumpWidget(
        pumpApp(
          Center(
            child: SizedBox.square(
              dimension: size,
              child: TimerDial(
                remaining: 25.minutes,
                color: Colors.red,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('3시 위치를 누르면 15분으로 onChanged를 부른다', (tester) async {
      final picked = <Duration>[];
      await pumpDial(tester, onChanged: picked.add);

      final center = tester.getCenter(find.byType(TimerDial));
      await tester.tapAt(center + const Offset(90, 0));

      expect(picked, [15.minutes]);
    });

    testWidgets('중심에서 6시 위치로 끌면 30분으로 onChanged를 부른다', (tester) async {
      final picked = <Duration>[];
      await pumpDial(tester, onChanged: picked.add);

      await tester.dragFrom(
        tester.getCenter(find.byType(TimerDial)),
        const Offset(0, 90),
      );

      expect(picked.last, 30.minutes);
    });

    testWidgets('같은 값이면 onChanged를 부르지 않는다', (tester) async {
      final picked = <Duration>[];
      await pumpDial(tester, onChanged: picked.add);

      // 25분 = 150도
      final center = tester.getCenter(find.byType(TimerDial));
      await tester.tapAt(center + const Offset(45, 77.94));

      expect(picked, isEmpty);
    });

    testWidgets('onChanged가 없으면 제스처를 받지 않는다', (tester) async {
      await pumpDial(tester);

      expect(
        find.descendant(
          of: find.byType(TimerDial),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    group('스크린 리더와 키보드', () {
      /// [remaining]에서 시작해 고른 값으로 다시 그리는 다이얼. 고른 값을 모은다
      Future<List<Duration>> pumpPicker(
        WidgetTester tester, {
        Duration remaining = const Duration(minutes: 25),
      }) async {
        final picked = <Duration>[];
        var current = remaining;
        await tester.pumpWidget(
          pumpApp(
            Center(
              child: SizedBox.square(
                dimension: 200,
                child: StatefulBuilder(
                  builder: (context, setState) => TimerDial(
                    remaining: current,
                    color: Colors.red,
                    label: '휴식 시간',
                    onChanged: (duration) {
                      picked.add(duration);
                      setState(() => current = duration);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        return picked;
      }

      final node = find.semantics.byLabel('휴식 시간');

      SemanticsNode dialNode(WidgetTester tester) =>
          tester.getSemantics(find.bySemanticsLabel('휴식 시간'));

      testWidgets('고를 수 있는 다이얼은 이름과 분 값을 가진 슬라이더이고 끌기 동작은 내보이지 않는다', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpPicker(tester);

        expect(
          dialNode(tester),
          isSemantics(
            isSlider: true,
            isFocusable: true,
            label: '휴식 시간',
            value: '25분',
            increasedValue: '26분',
            decreasedValue: '24분',
            hasIncreaseAction: true,
            hasDecreaseAction: true,
            hasScrollUpAction: false,
            hasScrollDownAction: false,
            hasScrollLeftAction: false,
            hasScrollRightAction: false,
          ),
        );
        handle.dispose();
      });

      testWidgets('스크린 리더의 늘리기·줄이기로 1분씩 바꾼다', (tester) async {
        final handle = tester.ensureSemantics();
        final picked = await pumpPicker(tester);

        tester.semantics.increase(node);
        await tester.pump();
        tester.semantics.increase(node);
        await tester.pump();
        tester.semantics.decrease(node);
        await tester.pump();

        expect(picked, [26.minutes, 27.minutes, 26.minutes]);
        expect(dialNode(tester), isSemantics(value: '26분'));
        handle.dispose();
      });

      for (final (minutes, increase, decrease) in [
        (1, true, false),
        (60, false, true),
      ]) {
        testWidgets('$minutes분에서는 1~60분 밖으로 바꾸지 않는다', (tester) async {
          final handle = tester.ensureSemantics();
          final picked = await pumpPicker(tester, remaining: minutes.minutes);

          expect(
            dialNode(tester),
            isSemantics(
              value: '$minutes분',
              hasIncreaseAction: increase,
              hasDecreaseAction: decrease,
            ),
          );

          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(
            increase
                ? LogicalKeyboardKey.arrowDown
                : LogicalKeyboardKey.arrowUp,
          );
          await tester.pump();

          expect(picked, isEmpty);
          handle.dispose();
        });
      }

      testWidgets('Tab으로 초점을 옮기고 방향키와 +·-로 1분씩 바꾼다', (tester) async {
        final picked = await pumpPicker(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<TimerDial>(),
          isNotNull,
        );

        for (final key in [
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
        ]) {
          await tester.sendKeyEvent(key);
          await tester.pump();
        }
        await tester.sendKeyDownEvent(LogicalKeyboardKey.equal, character: '+');
        await tester.sendKeyUpEvent(LogicalKeyboardKey.equal);
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.minus, character: '-');
        await tester.sendKeyUpEvent(LogicalKeyboardKey.minus);
        await tester.pump();

        expect(picked, [
          26.minutes,
          27.minutes,
          26.minutes,
          25.minutes,
          24.minutes,
          25.minutes,
          24.minutes,
        ]);
      });

      testWidgets('분 아래 초가 남아 있어도 늘리기·줄이기는 1~60분의 정수 분으로 고른다', (tester) async {
        final handle = tester.ensureSemantics();
        final picked = await pumpPicker(
          tester,
          remaining: const Duration(minutes: 25, seconds: 30),
        );

        tester.semantics.increase(node);
        await tester.pump();
        tester.semantics.decrease(node);
        await tester.pump();

        expect(picked, hasLength(2));
        for (final duration in picked) {
          expect(duration.inSeconds % 60, 0, reason: '$duration');
          expect(duration.inMinutes, inInclusiveRange(1, 60));
        }
        handle.dispose();
      });

      testWidgets('60분을 넘는 다이얼은 그 다이얼 끝까지 1분씩 늘린다', (tester) async {
        final handle = tester.ensureSemantics();
        final picked = await pumpPicker(tester, remaining: 90.minutes);

        tester.semantics.increase(node);
        await tester.pump();

        expect(picked, [91.minutes]);
        expect(dialNode(tester), isSemantics(value: '91분'));
        handle.dispose();
      });

      testWidgets('초점이 없으면 방향키로 바꾸지 않는다', (tester) async {
        final picked = await pumpPicker(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        expect(picked, isEmpty);
      });

      testWidgets('고를 수 없는 다이얼은 슬라이더가 아니고 초점을 받지 않는다', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpDial(tester);

        expect(find.bySemanticsLabel('휴식 시간'), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<TimerDial>(),
          isNull,
        );
        handle.dispose();
      });
    });

    testWidgets('작은 다이얼(80px)도 숫자 없이 그린다', (tester) async {
      await pumpDial(tester, size: 80);

      expect(
        find.descendant(
          of: find.byType(TimerDial),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

extension on int {
  Duration get minutes => Duration(minutes: this);
}
