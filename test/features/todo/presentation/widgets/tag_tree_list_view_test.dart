import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/todo/presentation/widgets/tag_tree_list_view.dart';
import 'package:momeet/shared/api/export.dart';

void main() {
  late TagRead testTag;

  setUp(() {
    testTag = TagRead(
      id: 'tag-1',
      name: '테스트 태그',
      color: '#FF5733',
      groupId: 'group-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  });

  Widget buildTestWidget({required TagRead tag}) {
    return MaterialApp(
      home: Scaffold(
        body: DraggableTagTile(
          tag: tag,
          groupColor: Colors.blue,
        ),
      ),
    );
  }

  group('DraggableTagTile 삭제 확인 다이얼로그', () {
    testWidgets('삭제 메뉴 선택 시 확인 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('태그 삭제'), findsOneWidget);
      expect(
        find.text(
          '태그 "테스트 태그"을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        ),
        findsOneWidget,
      );
      expect(find.text('취소'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '삭제'), findsOneWidget);
    });

    testWidgets('다이얼로그에서 취소 시 SnackBar가 표시되지 않는다', (tester) async {
      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(
        find.text('태그 삭제 기능이 곧 구현됩니다'),
        findsNothing,
      );
    });

    testWidgets('다이얼로그에서 삭제 확인 시 SnackBar가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();

      expect(
        find.text('태그 삭제 기능이 곧 구현됩니다'),
        findsOneWidget,
      );
    });

    testWidgets('다이얼로그가 닫힌 뒤에만 SnackBar가 표시된다 (await 동작 검증)', (tester) async {
      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('태그 삭제'), findsOneWidget);
      expect(find.text('태그 삭제 기능이 곧 구현됩니다'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();

      expect(find.text('태그 삭제'), findsNothing);
      expect(find.text('태그 삭제 기능이 곧 구현됩니다'), findsOneWidget);
    });
  });
}
