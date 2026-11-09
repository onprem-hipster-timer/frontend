import 'dart:math' as math;

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

    /// 60분 다이얼에서 [seconds]초를 가리키는 위치
    Offset at(int seconds) => _dialPoint(const Offset(100, 100), 90, seconds);

    test('3시·6시·9시는 15·30·45분', () {
      expect(dialDurationAt(const Offset(190, 100), size, face), 15.minutes);
      expect(dialDurationAt(const Offset(100, 190), size, face), 30.minutes);
      expect(dialDurationAt(const Offset(10, 100), size, face), 45.minutes);
    });

    test('정확히 12시는 30초, 12시 바로 앞은 60분', () {
      expect(
        dialDurationAt(const Offset(100, 10), size, face),
        const Duration(seconds: 30),
      );
      expect(dialDurationAt(const Offset(99, 10), size, face), 60.minutes);
    });

    test('중심 가까이(한 변의 5% 안쪽)는 null', () {
      expect(dialDurationAt(const Offset(100, 100), size, face), isNull);
      expect(dialDurationAt(const Offset(109, 100), size, face), isNull);
    });

    test('30초 단위로 반올림한다', () {
      // 12분 40초와 12분 50초 자리
      expect(dialDurationAt(at(760), size, face), 12.5.minutesExact);
      expect(dialDurationAt(at(770), size, face), 13.minutes);
    });

    test('끄는 동안 쓰는 10초 단위로도 읽는다', () {
      expect(
        dialDurationAt(at(760), size, face, step: dialDragStep),
        const Duration(minutes: 12, seconds: 40),
      );
      expect(
        dialDurationAt(const Offset(100, 10), size, face, step: dialDragStep),
        const Duration(seconds: 10),
      );
    });

    test('120분 다이얼의 3시는 30분', () {
      expect(
        dialDurationAt(const Offset(190, 100), size, 120.minutes),
        30.minutes,
      );
    });
  });

  group('snapDialDuration', () {
    test('가장 가까운 30초로 반올림하고 30초~한 바퀴로 자른다', () {
      const face = dialFaceDuration;
      expect(
        snapDialDuration(const Duration(minutes: 12, seconds: 40), face),
        12.5.minutesExact,
      );
      expect(
        snapDialDuration(const Duration(minutes: 12, seconds: 50), face),
        13.minutes,
      );
      expect(
        snapDialDuration(const Duration(seconds: 10), face),
        const Duration(seconds: 30),
      );
      expect(snapDialDuration(61.minutes, face), 60.minutes);
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
            increasedValue: '25분 30초',
            decreasedValue: '24분 30초',
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

      testWidgets('스크린 리더의 늘리기·줄이기로 30초씩 바꾼다', (tester) async {
        final handle = tester.ensureSemantics();
        final picked = await pumpPicker(tester);

        tester.semantics.increase(node);
        await tester.pump();
        tester.semantics.increase(node);
        await tester.pump();
        tester.semantics.decrease(node);
        await tester.pump();

        expect(picked, [25.5.minutesExact, 26.minutes, 25.5.minutesExact]);
        expect(dialNode(tester), isSemantics(value: '25분 30초'));
        handle.dispose();
      });

      for (final (remaining, value, increase, decrease) in [
        (const Duration(seconds: 30), '30초', true, false),
        (const Duration(minutes: 60), '60분', false, true),
      ]) {
        testWidgets('$value에서는 30초~60분 밖으로 바꾸지 않는다', (tester) async {
          final handle = tester.ensureSemantics();
          final picked = await pumpPicker(tester, remaining: remaining);

          expect(
            dialNode(tester),
            isSemantics(
              value: value,
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

      testWidgets('Tab으로 초점을 옮기고 방향키와 +·-로 30초씩 바꾼다', (tester) async {
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
          25.5.minutesExact,
          26.minutes,
          25.5.minutesExact,
          25.minutes,
          24.5.minutesExact,
          25.minutes,
          24.5.minutesExact,
        ]);
      });

      testWidgets('30초 단위가 아닌 값에서도 늘리기·줄이기는 30초씩 옮긴다', (tester) async {
        final handle = tester.ensureSemantics();
        final picked = await pumpPicker(
          tester,
          remaining: const Duration(minutes: 25, seconds: 10),
        );

        tester.semantics.increase(node);
        await tester.pump();
        tester.semantics.decrease(node);
        await tester.pump();

        expect(picked, [
          const Duration(minutes: 25, seconds: 40),
          const Duration(minutes: 25, seconds: 10),
        ]);
        handle.dispose();
      });

      testWidgets('60분을 넘는 다이얼은 그 다이얼 끝까지 30초씩 늘린다', (tester) async {
        final handle = tester.ensureSemantics();
        final picked = await pumpPicker(tester, remaining: 90.minutes);

        tester.semantics.increase(node);
        await tester.pump();

        expect(picked, [90.5.minutesExact]);
        expect(dialNode(tester), isSemantics(value: '90분 30초'));
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
  group('TimerDial 끌기', () {
    /// 고른 값으로 다시 그리는 25분 다이얼. 미리 보인 값과 고른 값을 모은다
    Future<({List<Duration?> previews, List<Duration> picked})> pumpDragged(
      WidgetTester tester,
    ) async {
      final previews = <Duration?>[];
      final picked = <Duration>[];
      var current = 25.minutes;
      await tester.pumpWidget(
        pumpApp(
          Center(
            child: SizedBox.square(
              dimension: 200,
              child: StatefulBuilder(
                builder: (context, setState) => TimerDial(
                  remaining: current,
                  color: Colors.red,
                  onPreview: previews.add,
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
      return (previews: previews, picked: picked);
    }

    Offset at(WidgetTester tester, int seconds) =>
        _dialPoint(tester.getCenter(find.byType(TimerDial)), 90, seconds);

    testWidgets('끄는 동안은 10초 단위로 미리 보이고 고르지 않는다', (tester) async {
      final result = await pumpDragged(tester);

      final gesture = await tester.startGesture(at(tester, 600));
      await gesture.moveTo(at(tester, 760));
      await tester.pump();

      expect(result.previews.last, const Duration(minutes: 12, seconds: 40));
      expect(result.picked, isEmpty);
      await gesture.up();
    });

    for (final (seconds, snapped) in [
      (760, const Duration(minutes: 12, seconds: 30)),
      (770, const Duration(minutes: 13)),
    ]) {
      testWidgets('$seconds초 자리에서 놓으면 가장 가까운 30초($snapped)를 고른다', (
        tester,
      ) async {
        final result = await pumpDragged(tester);

        final gesture = await tester.startGesture(at(tester, 600));
        await gesture.moveTo(at(tester, seconds));
        await gesture.up();
        await tester.pump();

        expect(result.picked, [snapped]);
        expect(result.previews.last, isNull);
      });
    }

    testWidgets('놓은 뒤 원판이 맞춘 값으로 움직이고 멈춘다', (tester) async {
      await pumpDragged(tester);

      final gesture = await tester.startGesture(at(tester, 600));
      await gesture.moveTo(at(tester, 760));
      await gesture.up();
      await tester.pump();

      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('끄는 동안 30초 경계를 넘을 때마다 선택 햅틱을 낸다', (tester) async {
      final haptics = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpDragged(tester);

      // 12분 0초에서 12분 20초까지는 같은 30초 칸이다
      final gesture = await tester.startGesture(at(tester, 720));
      await gesture.moveTo(at(tester, 740));
      await tester.pump();
      expect(haptics, isEmpty);

      await gesture.moveTo(at(tester, 760));
      await tester.pump();
      await gesture.moveTo(at(tester, 800));
      await tester.pump();
      await gesture.up();

      expect(haptics, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
    });

    testWidgets('끌기가 취소되어도 놓은 것처럼 가장 가까운 30초를 고른다', (tester) async {
      final result = await pumpDragged(tester);

      final gesture = await tester.startGesture(at(tester, 600));
      await gesture.moveTo(at(tester, 760));
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(result.picked, [const Duration(minutes: 12, seconds: 30)]);
      expect(result.previews.last, isNull);
    });
  });
}

extension on int {
  Duration get minutes => Duration(minutes: this);
}

extension on double {
  Duration get minutesExact => Duration(seconds: (this * 60).round());
}

/// [center]에서 [radius]만큼 떨어져 60분 다이얼의 [seconds]초를 가리키는 위치
Offset _dialPoint(Offset center, double radius, int seconds) {
  final angle = seconds / 3600 * 2 * math.pi;
  return center + Offset(math.sin(angle), -math.cos(angle)) * radius;
}
