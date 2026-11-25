import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  testWidgets('수정·삭제의 글자는 앱 글꼴로 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppEditDeleteButtons(onEdit: () {}, onDelete: () {}),
        ),
      ),
    );

    for (final label in ['수정', '삭제']) {
      final style = DefaultTextStyle.of(tester.element(find.text(label))).style;
      expect(style.fontFamily, AppTheme.fontFamily, reason: label);
    }
  });
}
