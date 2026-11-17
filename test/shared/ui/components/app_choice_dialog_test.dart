import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  /// 다이얼로그를 열고, 닫힌 뒤 결과를 돌려줄 getter를 준다.
  Future<String? Function()> open(
    WidgetTester tester, {
    String? selected,
  }) async {
    String? result;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAppChoiceDialog<String>(
                context,
                title: '제목',
                content: '내용',
                choices: const [
                  AppDialogChoice(value: 'a', label: '첫째', description: '설명'),
                  AppDialogChoice(value: 'b', label: '둘째'),
                ],
                selected: selected,
              );
              closed = true;
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('제목'), findsOneWidget);
    return () {
      expect(closed, isTrue, reason: '다이얼로그가 아직 안 닫힘');
      return result;
    };
  }

  testWidgets('선택지를 고르면 그 값을 돌려준다', (tester) async {
    final result = await open(tester);
    await tester.tap(find.text('둘째'));
    await tester.pumpAndSettle();
    expect(find.text('제목'), findsNothing);
    expect(result(), 'b');
  });

  testWidgets('지금 고른 값에만 체크 표시를 한다', (tester) async {
    await open(tester, selected: 'b');

    Finder checkIn(String label) => find.descendant(
      of: find.widgetWithText(ListTile, label),
      matching: find.byIcon(Icons.check),
    );
    expect(checkIn('둘째'), findsOneWidget);
    expect(checkIn('첫째'), findsNothing);
  });

  testWidgets('고른 값이 없으면 체크 표시가 없다', (tester) async {
    await open(tester);

    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('취소하면 null이다', (tester) async {
    final result = await open(tester);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result(), isNull);
  });
}
