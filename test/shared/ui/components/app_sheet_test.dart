import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

void main() {
  /// 안쪽 내비게이터 안의 버튼으로 [open]을 부른다
  Future<void> pumpNested(
    WidgetTester tester,
    void Function(BuildContext context) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          bottomNavigationBar: const SizedBox(height: 80, child: Text('내비 바')),
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => open(context),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('루트 내비게이터에 손잡이를 단 시트로 열고 고른 값을 돌려준다', (tester) async {
    String? result;
    await pumpNested(tester, (context) async {
      result = await showAppSheet<String>(
        context,
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).pop('골랐다'),
          child: const Text('고르기'),
        ),
      );
    });

    final sheetBottom = tester.getRect(find.byType(BottomSheet)).bottom;
    expect(
      sheetBottom,
      tester.view.physicalSize.height / tester.view.devicePixelRatio,
    );
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle,
      isTrue,
    );

    await tester.tap(find.text('고르기'));
    await tester.pumpAndSettle();
    expect(result, '골랐다');
  });

  testWidgets('키보드가 올라오면 그만큼 내용을 올린다', (tester) async {
    await pumpNested(
      tester,
      (context) => showAppSheet<void>(
        context,
        builder: (context) => const SizedBox(height: 50, child: Text('내용')),
      ),
    );
    final before = tester.getRect(find.text('내용')).bottom;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    // viewInsets는 물리 픽셀이다
    expect(
      tester.getRect(find.text('내용')).bottom,
      before - 300 / tester.view.devicePixelRatio,
    );
  });

  testWidgets('긴 목록 시트는 받은 비율 높이로 열고 컨트롤러를 목록에 넘긴다', (tester) async {
    ScrollController? given;
    await pumpNested(
      tester,
      (context) => showAppScrollableSheet<void>(
        context,
        initialSize: 0.5,
        builder: (context, controller) {
          given = controller;
          return ListView(
            controller: controller,
            children: [for (var i = 0; i < 50; i++) Text('줄 $i')],
          );
        },
      ),
    );

    final sheet = tester.widget<DraggableScrollableSheet>(
      find.byType(DraggableScrollableSheet),
    );
    expect(sheet.initialChildSize, 0.5);
    expect(sheet.expand, isFalse);
    expect(given, isNotNull);
  });
}
