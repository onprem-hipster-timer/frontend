import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  testWidgets('builder가 만든 다이얼로그를 띄우고, 닫을 때 넘긴 값을 돌려준다', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showAppDialog<String>(
                context,
                builder: (context) => AlertDialog(
                  title: const Text('제목'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop('닫음'),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('제목'), findsOneWidget);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('제목'), findsNothing);
    expect(result, '닫음');
  });
}
