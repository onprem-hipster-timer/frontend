import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('dialDurationAt 경계', () {
    const size = 200.0;

    test('다이얼 밖 좌표도 각도로 읽는다', () {
      expect(
        dialDurationAt(const Offset(250, 100), size, dialFaceDuration),
        const Duration(minutes: 15),
      );
      expect(
        dialDurationAt(const Offset(-50, 100), size, dialFaceDuration),
        const Duration(minutes: 45),
      );
    });

    test('600분 판의 6시는 300분', () {
      expect(
        dialDurationAt(
          const Offset(100, 190),
          size,
          const Duration(minutes: 600),
        ),
        const Duration(minutes: 300),
      );
    });
  });

  group('TimerDial 그리기 경계', () {
    Future<void> pump(
      WidgetTester tester, {
      required Duration remaining,
      Duration? face,
      double size = 200,
      ValueChanged<Duration>? onChanged,
    }) async {
      await tester.pumpWidget(
        pumpApp(
          Center(
            child: SizedBox.square(
              dimension: size,
              child: TimerDial(
                remaining: remaining,
                face: face,
                color: Colors.red,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    }

    testWidgets('남은 시간이 판보다 길어도 예외 없이 그린다', (tester) async {
      await pump(
        tester,
        remaining: const Duration(minutes: 90),
        face: dialFaceDuration,
      );
    });

    testWidgets('남은 시간 0도 그린다', (tester) async {
      await pump(tester, remaining: Duration.zero);
    });

    testWidgets('크기 0도 예외 없다', (tester) async {
      await pump(tester, remaining: const Duration(minutes: 25), size: 0);
    });

    testWidgets('600분 판도 그린다', (tester) async {
      await pump(tester, remaining: const Duration(minutes: 600));
    });

    testWidgets('중심을 가로질러 끌어도 놓은 위치의 값 하나만 고른다', (tester) async {
      final picked = <Duration>[];
      await pump(
        tester,
        remaining: const Duration(minutes: 25),
        onChanged: picked.add,
      );
      final center = tester.getCenter(find.byType(TimerDial));
      final gesture = await tester.startGesture(center + const Offset(90, 0));
      await gesture.moveTo(center);
      await gesture.moveTo(center + const Offset(-90, 0));
      await gesture.up();
      await tester.pump();
      expect(picked, [const Duration(minutes: 45)]);
      expect(tester.takeException(), isNull);
    });
  });
}
