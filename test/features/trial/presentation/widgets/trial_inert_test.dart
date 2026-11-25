import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_inert.dart';

/// 앞뒤에 누를 수 있는 단추를 두고, 가운데 [TrialInert] 안에 아이콘 단추를 둔다
Widget _app({
  required VoidCallback onInside,
  required VoidCallback onOutside,
}) => MaterialApp(
  home: Scaffold(
    body: Column(
      children: [
        TextButton(onPressed: onOutside, child: const Text('앞')),
        TrialInert(
          child: IconButton(
            tooltip: '공유 설정',
            icon: const Icon(Icons.lock_outline),
            onPressed: onInside,
          ),
        ),
        TextButton(onPressed: onOutside, child: const Text('뒤')),
      ],
    ),
  ),
);

/// 지금 포커스가 [TrialInert] 안에 있다
bool _focusInside(WidgetTester tester) {
  final context = FocusManager.instance.primaryFocus?.context;
  return context != null &&
      find
          .ancestor(
            of: find.byWidget(context.widget),
            matching: find.byType(TrialInert),
          )
          .evaluate()
          .isNotEmpty;
}

void main() {
  testWidgets('안의 단추를 눌러도 반응하지 않는다', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(_app(onInside: () => pressed++, onOutside: () {}));

    await tester.tap(find.byTooltip('공유 설정'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(pressed, 0);
  });

  for (final reverse in [false, true]) {
    final keys = reverse ? 'Shift+Tab' : 'Tab';
    testWidgets('$keys으로 포커스를 옮기면 안의 단추를 건너뛰고 Enter·Space에도 반응하지 않는다', (
      tester,
    ) async {
      var pressed = 0;
      var outside = 0;
      await tester.pumpWidget(
        _app(onInside: () => pressed++, onOutside: () => outside++),
      );

      final visited = <String>[];
      for (var i = 0; i < 6; i++) {
        if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();
        expect(_focusInside(tester), isFalse);
        final label = FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TextButton>();
        if (label != null) visited.add((label.child! as Text).data!);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        // 포커스 둘레에 말풍선이 뜨지 않는다
        expect(find.text('공유 설정'), findsNothing);
      }

      expect(pressed, 0);
      // 바깥 단추는 그대로 키보드로 옮겨 가 누를 수 있다
      expect(visited, containsAll(['앞', '뒤']));
      expect(outside, greaterThan(0));
    });
  }

  testWidgets('스크린 리더에는 이름을 읽히되 누르기·길게 누르기 동작은 없고, 보내도 반응하지 않는다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var pressed = 0;
    await tester.pumpWidget(_app(onInside: () => pressed++, onOutside: () {}));

    final inside = find.semantics.byPredicate(
      (node) => node.tooltip == '공유 설정',
    );
    expect(inside, findsOne);
    final data = inside.evaluate().single.getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    expect(data.hasAction(SemanticsAction.longPress), isFalse);
    expect(data.hasAction(SemanticsAction.focus), isFalse);

    for (final action in [SemanticsAction.tap, SemanticsAction.longPress]) {
      tester.semantics.performAction(inside, action, checkForAction: false);
    }
    await tester.pumpAndSettle();
    expect(pressed, 0);

    // 바깥 단추는 그대로 누르기 동작이 있다
    expect(
      find.semantics
          .byLabel('앞')
          .evaluate()
          .single
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    semantics.dispose();
  });
}
