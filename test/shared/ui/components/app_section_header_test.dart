import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SizedBox(width: 300, child: child)),
    ),
  );

  testWidgets('제목을 굵은 titleMedium으로 그린다', (tester) async {
    await pump(tester, const AppSectionHeader('태그'));

    final text = tester.widget<Text>(find.text('태그'));
    final titleMedium = Theme.of(
      tester.element(find.text('태그')),
    ).textTheme.titleMedium!;
    expect(text.style?.fontSize, titleMedium.fontSize);
    expect(text.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('trailing은 오른쪽 끝에 둔다', (tester) async {
    await pump(
      tester,
      AppSectionHeader(
        '태그',
        trailing: TextButton(onPressed: () {}, child: const Text('새 태그')),
      ),
    );

    expect(tester.getTopRight(find.byType(TextButton)).dx, 300);
    expect(
      tester.getTopLeft(find.text('태그')).dx,
      lessThan(tester.getTopLeft(find.text('새 태그')).dx),
    );
  });
}
