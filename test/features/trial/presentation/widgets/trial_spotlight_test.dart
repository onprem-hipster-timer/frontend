import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_spotlight.dart';

/// [target]을 강조한 두 단추. [disableAnimations]면 애니메이션을 줄인 화면이다
Widget _app({
  TrialSpotlightTarget? target,
  bool disableAnimations = true,
  double gap = 0,
  List<String>? pressed,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: Center(
        child: TrialSpotlight(
          target: target,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: gap),
              FilledButton(
                onPressed: () => pressed?.add('시작하기'),
                child: const Text('시작하기'),
              ),
              OutlinedButton(
                onPressed: () => pressed?.add('나중에'),
                child: const Text('나중에'),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

final _ring = find.byKey(TrialSpotlight.ringKey);

Rect _buttonRect(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.ancestor(of: _ring, matching: find.byType(FadeTransition)).first,
    )
    .opacity
    .value;

void main() {
  final start = TrialSpotlightTarget.button('시작하기', radius: 20);

  testWidgets('강조할 단추를 찾으면 그 단추와 같은 자리에 테두리를 하나 그린다', (tester) async {
    await tester.pumpWidget(_app(target: start));
    await tester.pump();

    expect(_ring, findsOneWidget);
    expect(tester.getRect(_ring), _buttonRect(tester, '시작하기'));
  });

  testWidgets('강조할 것이 없거나 찾지 못하면 테두리를 그리지 않는다', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(_ring, findsNothing);

    await tester.pumpWidget(
      _app(target: TrialSpotlightTarget.button('없는 단추', radius: 20)),
    );
    await tester.pump();
    expect(_ring, findsNothing);
  });

  testWidgets('강조한 단추를 눌러도 그대로 눌린다', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(_app(target: start, pressed: pressed));
    await tester.pump();

    await tester.tapAt(tester.getCenter(_ring));
    expect(pressed, ['시작하기']);
  });

  testWidgets('강조할 단추가 움직이면 테두리가 따라가고 배치는 그대로다', (tester) async {
    await tester.pumpWidget(_app(target: start));
    await tester.pump();
    final before = _buttonRect(tester, '나중에');

    await tester.pumpWidget(_app(target: start, gap: 40));
    await tester.pump();

    expect(tester.getRect(_ring), _buttonRect(tester, '시작하기'));
    expect(_buttonRect(tester, '나중에').top, before.top + 20);
  });

  testWidgets('강조할 것을 바꾸면 테두리가 새 단추로 옮겨 간다', (tester) async {
    await tester.pumpWidget(_app(target: start));
    await tester.pump();

    await tester.pumpWidget(
      _app(target: TrialSpotlightTarget.button('나중에', radius: 20)),
    );
    await tester.pump();

    expect(_ring, findsOneWidget);
    expect(tester.getRect(_ring), _buttonRect(tester, '나중에'));
  });

  testWidgets('애니메이션을 줄였으면 테두리가 바로 보이고 움직이지 않는다', (tester) async {
    await tester.pumpWidget(_app(target: start));
    await tester.pump();

    expect(_opacity(tester), 1);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('애니메이션을 줄이지 않았으면 내용이 자리 잡은 뒤 나타나 천천히 되풀이해 퍼진다', (tester) async {
    await tester.pumpWidget(_app(target: start, disableAnimations: false));
    await tester.pump();
    expect(_opacity(tester), 0);

    await tester.pump(TrialSpotlight.settle);
    await tester.pump(const Duration(seconds: 1));
    expect(_opacity(tester), 1);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump(TrialSpotlight.pulse * 3);
    expect(tester.binding.hasScheduledFrame, isTrue);

    // 움직이는 것을 내려 다음 테스트로 남기지 않는다
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('어두운 테마에서도 테마의 주색으로 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: TrialSpotlight(
              target: start,
              child: FilledButton(onPressed: () {}, child: const Text('시작하기')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final primary = Theme.of(tester.element(_ring)).colorScheme.primary;
    expect(_ring, paints..rrect(color: primary));
  });
}
