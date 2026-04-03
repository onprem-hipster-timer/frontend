import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/features/todo/presentation/widgets/tag_tree_list_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

class MockTagsClient extends Mock implements TagsClient {}

class FakeTagUpdate extends Fake implements TagUpdate {}

class FakeTagCreate extends Fake implements TagCreate {}

void main() {
  late TagRead testTag;
  late MockTagsClient mockTagsClient;

  setUpAll(() {
    registerFallbackValue(FakeTagUpdate());
    registerFallbackValue(FakeTagCreate());
  });

  setUp(() {
    testTag = TagRead(
      id: 'tag-1',
      name: '테스트 태그',
      color: '#FF5733',
      groupId: 'group-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
    mockTagsClient = MockTagsClient();

    // 기본 mock: tagGroups 조회 (tagMutations가 invalidate 시 필요)
    when(
      () => mockTagsClient.readTagGroupsV1TagsGroupsGet(
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => <TagGroupReadWithTags>[]);
  });

  Widget buildTestWidget({required TagRead tag}) {
    return ProviderScope(
      overrides: [tagsApiProvider.overrideWithValue(mockTagsClient)],
      child: MaterialApp(
        home: Scaffold(
          body: DraggableTagTile(tag: tag, groupColor: Colors.blue),
        ),
      ),
    );
  }

  group('DraggableTagTile UI 렌더링', () {
    testWidgets('태그 이름과 PopupMenuButton이 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(tag: testTag));

      expect(find.text('테스트 태그'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('설명이 있으면 표시된다', (tester) async {
      final tagWithDesc = TagRead(
        id: 'tag-2',
        name: '설명 태그',
        color: '#00FF00',
        groupId: 'group-1',
        description: '태그 설명입니다',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );
      await tester.pumpWidget(buildTestWidget(tag: tagWithDesc));

      expect(find.text('태그 설명입니다'), findsOneWidget);
    });
  });

  group('DraggableTagTile 삭제 확인 다이얼로그', () {
    testWidgets('삭제 메뉴 선택 시 확인 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('태그 삭제'), findsOneWidget);
      expect(
        find.text('태그 "테스트 태그"을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        findsOneWidget,
      );
      expect(find.text('취소'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '삭제'), findsOneWidget);
    });

    testWidgets('다이얼로그에서 취소 시 API가 호출되지 않는다', (tester) async {
      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockTagsClient.deleteTagV1TagsTagIdDelete(
          tagId: any(named: 'tagId'),
          options: any(named: 'options'),
        ),
      );
    });

    testWidgets('삭제 확인 시 API가 호출되고 성공 SnackBar가 표시된다', (tester) async {
      when(
        () => mockTagsClient.deleteTagV1TagsTagIdDelete(
          tagId: 'tag-1',
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();

      verify(
        () => mockTagsClient.deleteTagV1TagsTagIdDelete(
          tagId: 'tag-1',
          options: any(named: 'options'),
        ),
      ).called(1);
      expect(find.text('테스트 태그 태그가 삭제되었습니다'), findsOneWidget);
    });

    testWidgets('삭제 실패 시 에러 SnackBar가 표시된다', (tester) async {
      when(
        () => mockTagsClient.deleteTagV1TagsTagIdDelete(
          tagId: 'tag-1',
          options: any(named: 'options'),
        ),
      ).thenThrow(Exception('서버 오류'));

      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, '삭제'));
      await tester.pumpAndSettle();

      expect(find.textContaining('태그 삭제에 실패했습니다'), findsOneWidget);
    });
  });

  group('DraggableTagTile 수정', () {
    testWidgets('수정 메뉴 선택 시 태그 폼 시트가 표시된다', (tester) async {
      // TagFormSheet가 태그의 그룹 정보를 조회하므로 해당 그룹을 포함한 mock 데이터 필요
      when(
        () => mockTagsClient.readTagGroupsV1TagsGroupsGet(
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => [
          TagGroupReadWithTags(
            id: 'group-1',
            name: '테스트 그룹',
            color: '#3498DB',
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
            tags: [testTag],
          ),
        ],
      );
      when(
        () => mockTagsClient.readTagsV1TagsGet(options: any(named: 'options')),
      ).thenAnswer((_) async => [testTag]);

      await tester.pumpWidget(buildTestWidget(tag: testTag));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      // TagFormSheet가 BottomSheet로 표시되고 '태그 수정' 타이틀이 보이는지 확인
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('태그 수정'), findsOneWidget);
    });
  });
}
