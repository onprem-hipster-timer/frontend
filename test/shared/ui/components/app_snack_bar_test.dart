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

  testWidgets('시트 위 알림도 남기기를 고르면 1분이 지나도 남는다', (tester) async {
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

    showAppSnackBar(sheetContext, '하나', persist: true);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('하나'), findsOneWidget);
  });

  group('버튼이 있는 알림', () {
    late BuildContext page;

    Future<void> open(WidgetTester tester, {bool screenReader = false}) async {
      await pumpSheetHost(tester, open: (context) => page = context);
      tester.platformDispatcher.accessibilityFeaturesTestValue = screenReader
          ? const FakeAccessibilityFeatures(accessibleNavigation: true)
          : const FakeAccessibilityFeatures();
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pump();
    }

    testWidgets('버튼이 있어도 4초 뒤 저절로 닫힌다', (tester) async {
      await open(tester);
      showAppSnackBar(page, '만들었습니다', actionLabel: '보기', onAction: () {});
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBarAction, '보기'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('닫히기 전에 버튼을 누르면 받은 동작을 부르고 닫힌다', (tester) async {
      var pressed = 0;
      await open(tester);
      showAppSnackBar(
        page,
        '만들었습니다',
        actionLabel: '보기',
        onAction: () => pressed++,
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      await tester.tap(find.widgetWithText(SnackBarAction, '보기'));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('스크린 리더를 쓰는 중에는 저절로 닫히지 않는다', (tester) async {
      await open(tester, screenReader: true);
      showAppSnackBar(page, '만들었습니다', actionLabel: '보기', onAction: () {});
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBarAction, '보기'), findsOneWidget);
    });

    testWidgets('남기기를 고르면 1분이 지나도 닫히지 않고, 버튼을 누르면 닫힌다', (tester) async {
      var pressed = 0;
      await open(tester);
      showAppSnackBar(
        page,
        '만들었습니다',
        actionLabel: '보기',
        onAction: () => pressed++,
        persist: true,
      );
      await tester.pumpAndSettle();

      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SnackBarAction, '보기'), findsOneWidget);

      await tester.tap(find.widgetWithText(SnackBarAction, '보기'));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('되돌리기 알림', () {
    late BuildContext page;
    late List<bool> results;

    Future<void> open(WidgetTester tester, {bool screenReader = false}) async {
      results = [];
      await pumpSheetHost(tester, open: (context) => page = context);
      tester.platformDispatcher.accessibilityFeaturesTestValue = screenReader
          ? const FakeAccessibilityFeatures(accessibleNavigation: true)
          : const FakeAccessibilityFeatures();
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pump();
    }

    void show(String message) => ScaffoldMessenger.of(
      page,
    ).showAppUndoSnackBar(message).then(results.add);

    testWidgets('되돌리기를 누르면 true로 끝난다', (tester) async {
      await open(tester);
      show('민수를 뺐습니다');
      await tester.pumpAndSettle();

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();

      expect(results, [true]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('시간이 다 되면 false로 끝나고 그 전에는 끝나지 않는다', (tester) async {
      await open(tester);
      show('민수를 뺐습니다');
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 4));
      expect(results, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(results, [false]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('새 알림이 덮으면 이전 것은 false로 끝난다', (tester) async {
      await open(tester);
      show('민수를 뺐습니다');
      await tester.pumpAndSettle();

      show('서연을 뺐습니다');
      await tester.pumpAndSettle();
      expect(results, [false]);

      await tester.tap(find.text('되돌리기'));
      await tester.pumpAndSettle();
      expect(results, [false, true]);
    });

    testWidgets('스크린 리더를 쓰는 중에는 저절로 닫히지 않는다', (tester) async {
      await open(tester, screenReader: true);
      show('민수를 뺐습니다');
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(results, isEmpty);
      expect(find.text('되돌리기'), findsOneWidget);
    });
  });
}
