import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_step_switcher.dart';

/// 높이 400 화면에서 높이 300 칸 아래에 [height] 높이의 [step]번 질문을 둔다. 애니메이션은 줄인 채다
Widget _app(int step, double height, {bool revealStart = false}) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(size: Size(360, 400), disableAnimations: true),
    child: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 300),
          MeetingStepSwitcher(
            step: step,
            announcement: '$step번 질문',
            revealStart: revealStart,
            child: SizedBox(
              key: ValueKey(step),
              height: height,
              width: double.infinity,
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  Future<Rect> next(
    WidgetTester tester,
    double height, {
    bool revealStart = false,
  }) async {
    tester.view.physicalSize = const Size(360, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(0, 50, revealStart: revealStart));
    await tester.pumpWidget(_app(1, height, revealStart: revealStart));
    await tester.pumpAndSettle();
    return tester.getRect(find.byKey(const ValueKey(1)));
  }

  testWidgets('다음 질문이 화면 아래로 넘치면 그 끝까지 보이게 굴린다', (tester) async {
    expect((await next(tester, 200)).bottom, 400);
  });

  testWidgets('다음 질문이 화면보다 길면 끝이 보이게 굴린다', (tester) async {
    expect((await next(tester, 600)).bottom, 400);
  });

  group('첫머리를 보이는 질문', () {
    testWidgets('화면보다 길면 첫머리가 화면 안에 남는다', (tester) async {
      final rect = await next(tester, 600, revealStart: true);

      expect(rect.top, inInclusiveRange(0, 400));
    });

    testWidgets('화면에 들어가면 끝까지 보이게 굴린다', (tester) async {
      expect((await next(tester, 200, revealStart: true)).bottom, 400);
    });
  });
}
