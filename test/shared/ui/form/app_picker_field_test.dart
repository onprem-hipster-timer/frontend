import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget field) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: field),
      ),
    ),
  );

  testWidgets('이름표와 값을 보이고 누르면 onTap을 부른다', (tester) async {
    var taps = 0;
    await pump(
      tester,
      AppPickerField(label: '마감일', value: '2026년 11월 20일', onTap: () => taps++),
    );

    expect(find.text('마감일'), findsOneWidget);
    expect(find.text('2026년 11월 20일'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    await tester.tap(find.text('2026년 11월 20일'));
    expect(taps, 1);
  });

  testWidgets('값이 없으면 placeholder를 보이고 지우기 버튼을 두지 않는다', (tester) async {
    await pump(
      tester,
      AppPickerField(
        label: '마감일',
        value: null,
        placeholder: '선택 안 함',
        onTap: () {},
        onClear: () {},
      ),
    );

    expect(find.text('선택 안 함'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);
  });

  testWidgets('값이 있고 onClear가 있으면 지우기 버튼이 onClear만 부른다', (tester) async {
    var taps = 0;
    var clears = 0;
    await pump(
      tester,
      AppPickerField(
        label: '마감일',
        value: '오늘',
        onTap: () => taps++,
        onClear: () => clears++,
      ),
    );

    await tester.tap(find.byTooltip('마감일 지우기'));
    expect(clears, 1);
    expect(taps, 0);
  });

  testWidgets('errorText를 칸 아래에 보인다', (tester) async {
    await pump(
      tester,
      AppPickerField(
        label: '종료',
        value: '9시',
        onTap: () {},
        errorText: '늦어야 합니다',
      ),
    );

    expect(find.text('늦어야 합니다'), findsOneWidget);
  });
}
