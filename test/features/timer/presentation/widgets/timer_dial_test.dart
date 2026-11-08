import 'package:flutter/material.dart';
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
