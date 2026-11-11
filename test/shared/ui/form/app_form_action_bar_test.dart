import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

import '../../../helpers/sheet_host.dart';

void main() {
  Finder submit(String label) => find.widgetWithText(FilledButton, label);
  Finder cancel() => find.widgetWithText(OutlinedButton, '취소');

  testWidgets('저장을 누르면 onSubmit을, 취소를 누르면 시트를 닫는다', (tester) async {
    var submitted = 0;
    await pumpSheetHost(
      tester,
      open: (context) => showAppSheet<void>(
        context,
        builder: (_) =>
            AppFormActionBar(submitLabel: '저장', onSubmit: () => submitted++),
      ),
    );

    await tester.tap(submit('저장'));
    expect(submitted, 1);
    await tapVisible(tester, cancel());
    expect(find.byType(AppFormActionBar), findsNothing);
  });

  testWidgets('onSubmit이 없으면 저장만 막는다', (tester) async {
    await pumpSheetHost(
      tester,
      open: (context) => showAppSheet<void>(
        context,
        builder: (_) =>
            const AppFormActionBar(submitLabel: '저장', onSubmit: null),
      ),
    );

    expect(tester.widget<FilledButton>(submit('저장')).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(cancel()).onPressed, isNotNull);
  });

  testWidgets('busy면 두 버튼을 막고 저장 자리에 진행 표시를 둔다', (tester) async {
    // 진행 표시가 계속 돌아 settle하지 않으므로 시트 없이 그린다
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormActionBar(
            submitLabel: '저장',
            onSubmit: () {},
            busy: true,
          ),
        ),
      ),
    );

    expect(find.text('저장'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<OutlinedButton>(cancel()).onPressed, isNull);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.byType(CircularProgressIndicator),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('onCancel을 주면 닫지 않고 그것을 부른다', (tester) async {
    var cancelled = 0;
    await pumpSheetHost(
      tester,
      open: (context) => showAppSheet<void>(
        context,
        builder: (_) => AppFormActionBar(
          submitLabel: '저장',
          onSubmit: () {},
          cancelLabel: '되돌리기',
          onCancel: () => cancelled++,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '되돌리기'));
    await tester.pumpAndSettle();
    expect(cancelled, 1);
    expect(find.byType(AppFormActionBar), findsOneWidget);
  });
}
