import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

import '../../../helpers/sheet_host.dart';

void main() {
  testWidgets('제목, 칸, 버튼 줄을 차례로 두고 칸 사이를 20 띄운다', (tester) async {
    await pumpSheetHost(
      tester,
      open: (context) => showAppSheet<void>(
        context,
        builder: (_) => AppFormSheet(
          title: '새 태그 만들기',
          actions: AppFormActionBar(submitLabel: '생성', onSubmit: () {}),
          children: const [Text('첫 칸'), Text('둘째 칸')],
        ),
      ),
    );

    final title = tester.getRect(find.text('새 태그 만들기'));
    final first = tester.getRect(find.text('첫 칸'));
    final second = tester.getRect(find.text('둘째 칸'));
    final submit = tester.getRect(find.text('생성'));
    expect(title.top < first.top && first.top < second.top, isTrue);
    expect(second.top - first.bottom, 20);
    expect(submit.top, greaterThan(second.bottom));
  });

  testWidgets('formKey로 칸들을 검사한다', (tester) async {
    final formKey = GlobalKey<FormState>();
    await pumpSheetHost(
      tester,
      open: (context) => showAppSheet<void>(
        context,
        builder: (_) => AppFormSheet(
          title: '폼',
          formKey: formKey,
          actions: AppFormActionBar(
            submitLabel: '저장',
            onSubmit: () => formKey.currentState!.validate(),
          ),
          children: [
            TextFormField(validator: (value) => value!.isEmpty ? '비었음' : null),
          ],
        ),
      ),
    );

    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(find.text('비었음'), findsOneWidget);
  });

  testWidgets('칸이 화면보다 길면 굴려 버튼 줄까지 갈 수 있다', (tester) async {
    await pumpSheetHost(
      tester,
      size: const Size(400, 500),
      open: (context) => showAppSheet<void>(
        context,
        builder: (_) => AppFormSheet(
          title: '긴 폼',
          actions: AppFormActionBar(submitLabel: '저장', onSubmit: () {}),
          children: [for (var i = 0; i < 20; i++) Text('칸 $i')],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('저장').hitTestable(), findsOneWidget);
  });
}
