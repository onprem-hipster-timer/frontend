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

  testWidgets('콜백이 없으면 수정·삭제가 누를 수 없는 모양이고 삭제도 오류색이 아니다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppEditDeleteButtons(onEdit: null, onDelete: null),
        ),
      ),
    );

    final error = AppTheme.light().colorScheme.error;
    for (final label in ['수정', '삭제']) {
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.enabled, isFalse, reason: label);
      expect(
        button.style?.foregroundColor?.resolve({WidgetState.disabled}),
        isNot(error),
        reason: label,
      );
    }
  });

  testWidgets('콜백이 있으면 삭제는 오류색이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppEditDeleteButtons(onEdit: () {}, onDelete: () {}),
        ),
      ),
    );

    final delete = tester.widget<OutlinedButton>(
      find.ancestor(of: find.text('삭제'), matching: find.byType(OutlinedButton)),
    );
    expect(
      delete.style?.foregroundColor?.resolve({}),
      AppTheme.light().colorScheme.error,
    );
  });
}
