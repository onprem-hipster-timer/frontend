import 'dart:ui' show Tristate;

import 'package:momeet/core/providers/retry_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/pages/todo_group_detail_page.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';

/// 할 일 그룹 화면의 트리 조작: 펼침·선택·상태·수정·삭제·끌어 옮기기
void main() {
  late FakeTodosClient todos;

  TodoRead todo(
    String id,
    String title, {
    String? parentId,
    TodoStatus status = TodoStatus.unscheduled,
    List<TagRead> tags = const [],
  }) => TodoRead(
    id: id,
    title: title,
    todoGroupId: 'group-work',
    parentId: parentId,
    status: status,
    tags: tags,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  setUp(() {
    todos = FakeTodosClient(
      [
        todo('todo-1', '보고서'),
        todo('todo-2', '자료 조사', parentId: 'todo-1'),
        todo('todo-3', '회의 준비'),
      ],
      [makeTodoGroup(id: 'group-work', name: '업무')],
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/todo/group-work',
      routes: [
        GoRoute(
          path: AppRoute.todo.path,
          name: AppRoute.todo.name,
          builder: (context, state) => const Scaffold(),
          routes: [
            GoRoute(
              path: ':groupId',
              name: AppRoute.todoGroupDetail.name,
              builder: (context, state) => TodoGroupDetailPage(
                groupId: state.pathParameters['groupId']!,
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          todosApiProvider.overrideWithValue(todos),
          tagsApiProvider.overrideWithValue(
            FakeTagsClient([makeTagGroup(id: 'group-work', name: '업무')]),
          ),
          activeTimersProvider.overrideWith((ref) async => const []),
          todoTimerAggregationsProvider.overrideWith((ref) async => const {}),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tileOf(String title) => find
      .ancestor(
        of: find.text(title),
        matching: find.byType(EditableTodoTreeTile),
      )
      .first;

  Finder inTile(String title, Finder finder) =>
      find.descendant(of: tileOf(title), matching: finder).first;

  /// [title] 줄만의 영역(하위 타일 제외)
  Finder rowOf(String title) => find
      .ancestor(of: find.text(title), matching: find.byType(TodoTreeTileView))
      .first;

  Future<void> expand(WidgetTester tester, String title) =>
      tapVisible(tester, inTile(title, find.byIcon(Icons.chevron_right)));

  Future<void> dragOnto(WidgetTester tester, String from, Finder to) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(from)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(tester.getCenter(to));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(to) + const Offset(1, 1));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  group('펼침', () {
    testWidgets('하위 할 일은 접혀 있고 개수를 보이며, 펼치고 다시 접을 수 있다', (tester) async {
      await pumpPage(tester);

      expect(find.text('자료 조사'), findsNothing);
      expect(
        find.descendant(of: rowOf('보고서'), matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: tileOf('회의 준비'),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
      );

      await expand(tester, '보고서');
      expect(find.text('자료 조사'), findsOneWidget);
      await expand(tester, '보고서');
      expect(find.text('자료 조사'), findsNothing);
    });
  });

  group('선택', () {
    testWidgets('누른 할 일만 강조한다', (tester) async {
      await pumpPage(tester);
      await tapVisible(tester, find.text('회의 준비'));
      await tapVisible(tester, find.widgetWithText(OutlinedButton, '취소'));

      bool selected(String title) =>
          tester.getSemantics(rowOf(title)).flagsCollection.isSelected ==
          Tristate.isTrue;

      expect(selected('회의 준비'), isTrue);
      expect(selected('보고서'), isFalse);
    });
  });

  group('표시', () {
    testWidgets('완료한 할 일은 제목에 취소선을 긋고, 태그는 첫 이름과 나머지 수를 보인다', (tester) async {
      todos.todos
        ..clear()
        ..add(
          todo(
            'todo-1',
            '보고서',
            status: TodoStatus.done,
            tags: [
              makeTag(id: 'a', name: '집중'),
              makeTag(id: 'b', name: '공부'),
              makeTag(id: 'c', name: '독서'),
            ],
          ),
        );
      await pumpPage(tester);

      expect(
        tester.widget<Text>(find.text('보고서')).style?.decoration,
        TextDecoration.lineThrough,
      );
      expect(find.text('집중'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });
  });

  group('상태 메뉴', () {
    testWidgets('메뉴에서 고른 상태로 바꾼다', (tester) async {
      await pumpPage(tester);
      await tapVisible(
        tester,
        inTile('회의 준비', find.byType(PopupMenuButton<TodoStatus>)),
      );

      for (final label in ['미예정', '예정됨', '완료', '취소']) {
        expect(find.text(label), findsWidgets);
      }
      await tapVisible(tester, find.text('완료').last);

      final (id, body, _) = todos.updated.single;
      expect(id, 'todo-3');
      expect(body.status, TodoStatus.done);
    });

    testWidgets('지금 상태를 고르면 보내지 않는다', (tester) async {
      await pumpPage(tester);
      await tapVisible(
        tester,
        inTile('회의 준비', find.byType(PopupMenuButton<TodoStatus>)),
      );
      await tapVisible(tester, find.text('미예정').last);

      expect(todos.updated, isEmpty);
    });
  });

  group('수정·삭제', () {
    testWidgets('수정 버튼은 그 할 일의 수정 시트를 연다', (tester) async {
      await pumpPage(tester);
      await tapVisible(tester, inTile('회의 준비', find.text('수정')));

      expect(find.text('할 일 수정'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '회의 준비'), findsOneWidget);
    });

    testWidgets('하위가 있으면 함께 지워진다고 알리고, 확인하면 지운 뒤 목록에서 뺀다', (tester) async {
      await pumpPage(tester);
      await tapVisible(tester, inTile('보고서', find.text('삭제')));

      expect(find.textContaining('하위 할 일 1개도 함께 삭제됩니다.'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(todos.deleted.single.$1, 'todo-1');
      expect(find.text('보고서이(가) 삭제되었습니다'), findsOneWidget);
      expect(find.text('보고서'), findsNothing);
    });

    testWidgets('삭제를 취소하면 지우지 않는다', (tester) async {
      await pumpPage(tester);
      await tapVisible(tester, inTile('회의 준비', find.text('삭제')));

      expect(find.textContaining('하위 할 일'), findsNothing);
      await tapVisible(tester, find.widgetWithText(TextButton, '취소'));
      expect(todos.deleted, isEmpty);
    });

    testWidgets('삭제에 실패하면 알린다', (tester) async {
      todos.writeError = Exception('서버 오류');
      await pumpPage(tester);
      await tapVisible(tester, inTile('회의 준비', find.text('삭제')));
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(find.textContaining('할 일 삭제에 실패했습니다'), findsOneWidget);
    });
  });

  group('끌어 옮기기', () {
    testWidgets('길게 눌러 다른 할 일 위에 놓으면 그 할 일의 하위로 옮긴다', (tester) async {
      await pumpPage(tester);
      await dragOnto(tester, '회의 준비', find.text('보고서'));

      final (id, body, _) = todos.updated.single;
      expect(id, 'todo-3');
      expect(body.parentId, 'todo-1');
    });

    testWidgets('자기 하위 위에는 놓을 수 없다', (tester) async {
      await pumpPage(tester);
      await expand(tester, '보고서');
      await dragOnto(tester, '보고서', find.text('자료 조사'));

      expect(todos.updated, isEmpty);
    });

    testWidgets('하위 할 일을 루트로 이동 위에 놓으면 부모를 null로 보내라고 표시한다', (tester) async {
      await pumpPage(tester);
      await expand(tester, '보고서');
      await dragOnto(tester, '자료 조사', find.text('루트로 이동'));

      final (id, body, options) = todos.updated.single;
      expect(id, 'todo-2');
      expect(body.parentId, isNull);
      expect(explicitNullFields(options), ['parent_id']);
    });

    testWidgets('이미 루트인 할 일은 루트로 이동에 놓아도 보내지 않는다', (tester) async {
      await pumpPage(tester);
      await dragOnto(tester, '회의 준비', find.text('루트로 이동'));

      expect(todos.updated, isEmpty);
    });
  });
}
