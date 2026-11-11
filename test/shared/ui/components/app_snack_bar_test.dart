import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

import '../../../helpers/sheet_host.dart';

void main() {
  testWidgets('화면에서는 SnackBar로 띄우고 이전 알림을 닫는다', (tester) async {
    await pumpSheetHost(
      tester,
      open: (context) {
        showAppSnackBar(context, '첫 알림');
        showAppSnackBar(context, '둘째 알림');
      },
    );

    expect(find.widgetWithText(SnackBar, '둘째 알림'), findsOneWidget);
    expect(find.text('첫 알림'), findsNothing);
  });

  testWidgets('오류는 error 색, 성공은 success 색으로 칠한다', (tester) async {
    late BuildContext page;
    await pumpSheetHost(tester, open: (context) => page = context);

    showAppSnackBar(page, '실패', kind: AppNoticeKind.error);
    await tester.pumpAndSettle();
    final theme = Theme.of(page);
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      theme.colorScheme.error,
    );

    showAppSnackBar(page, '성공', kind: AppNoticeKind.success);
    await tester.pumpAndSettle();
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor,
      AppColors.of(page).success,
    );
  });

  testWidgets('시트 안에서 띄우면 시트에 가리지 않고 그 위에서 누를 수 있다', (tester) async {
    var acted = 0;
    await pumpSheetHost(
      tester,
      open: (context) => showAppSheet<void>(
        context,
        builder: (sheet) => SizedBox(
          height: 400,
          child: Center(
            child: TextButton(
              onPressed: () => showAppSnackBar(
                sheet,
                '저장에 실패했습니다',
                kind: AppNoticeKind.error,
                actionLabel: '다시',
                onAction: () => acted++,
              ),
              child: const Text('저장'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('저장'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('저장에 실패했습니다'), findsOneWidget);
    final sheet = tester.getRect(find.byType(BottomSheet));
    final notice = tester.getRect(find.text('저장에 실패했습니다'));
    expect(sheet.overlaps(notice), isTrue);

    await tester.tap(find.text('다시'));
    await tester.pump();
    expect(acted, 1);
  });

  testWidgets('시트 위 알림은 잠시 뒤 사라지고, 새 알림은 이전 것을 바꾼다', (tester) async {
    late BuildContext sheetContext;
    await pumpSheetHost(
      tester,
      open: (context) => showAppSheet<void>(
        context,
        builder: (sheet) {
          sheetContext = sheet;
          return const SizedBox(height: 200);
        },
      ),
    );

    showAppSnackBar(sheetContext, '하나');
    await tester.pump(const Duration(milliseconds: 300));
    showAppSnackBar(sheetContext, '둘');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('하나'), findsNothing);
    expect(find.text('둘'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('둘'), findsNothing);
  });
}
