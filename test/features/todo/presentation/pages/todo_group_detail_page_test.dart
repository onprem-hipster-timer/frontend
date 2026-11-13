import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/pages/todo_group_detail_page.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_group_field.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTodosClient todos;
  late FakeTagsClient tags;
  late GoRouter router;

  TodoRead todo(String id, String title, {String? parentId, String? group}) =>
      TodoRead(
        id: id,
        title: title,
        todoGroupId: group ?? 'group-work',
        parentId: parentId,
        status: TodoStatus.unscheduled,
        createdAt: DateTime.utc(2026, 1, 1),
      );

  setUp(() {
    todos = FakeTodosClient(
      [
        todo('todo-1', '보고서'),
        todo('todo-2', '자료 조사', parentId: 'todo-1'),
        todo('todo-3', '회의 준비'),
        todo('todo-9', '다른 그룹 일', group: 'group-study'),
      ],
      [
        makeTodoGroup(id: 'group-work', name: '업무', description: '회사 일'),
        makeTodoGroup(id: 'group-study', name: '학습'),
      ],
    );
    tags = FakeTagsClient();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    String groupId = 'group-work',
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: '/todo/$groupId',
      routes: [
        GoRoute(
          path: AppRoute.todo.path,
          name: AppRoute.todo.name,
          builder: (context, state) => const Scaffold(body: Text('대시보드 화면')),
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
          tagsApiProvider.overrideWithValue(tags),
          activeTimersProvider.overrideWith((ref) async => const []),
          todoTimerAggregationsProvider.overrideWith((ref) async => const {}),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('그룹 이름·설명과 이 그룹의 최상위 할 일만 보인다', (tester) async {
    await pumpPage(tester);

    expect(todos.readGroupIds.last, ['group-work']);
    expect(find.text('업무'), findsOneWidget);
    expect(find.text('회사 일'), findsOneWidget);
    expect(find.text('보고서'), findsOneWidget);
    expect(find.text('회의 준비'), findsOneWidget);
    expect(find.text('자료 조사'), findsNothing);
    expect(find.text('다른 그룹 일'), findsNothing);
  });

  testWidgets('목록에 없는 그룹이면 기본 제목을 보이고 설정 버튼이 없다', (tester) async {
    await pumpPage(tester, groupId: 'group-gone');

    expect(find.text('할 일 그룹'), findsOneWidget);
    expect(find.byTooltip('할 일 그룹 설정'), findsNothing);
  });

  testWidgets('뒤로 가기는 대시보드로 간다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byIcon(Icons.arrow_back));

    expect(location(), AppRoute.todo.path);
  });

  testWidgets('추가 버튼은 이 그룹에 할 일을 만들고 목록에 넣는다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byTooltip('이 할 일 그룹에 할 일 추가'));
    await tester.enterText(find.widgetWithText(TextFormField, '할 일 제목'), '정리');
    await tapVisible(tester, find.text('생성'));

    expect(todos.created.single.todoGroupId, 'group-work');
    expect(find.text('정리'), findsOneWidget);
  });

  testWidgets('할 일을 누르면 그 할 일의 수정 시트를 연다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.text('회의 준비'));

    expect(find.text('할 일 수정'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '회의 준비'), findsOneWidget);
  });

  testWidgets('할 일을 다른 그룹으로 옮기면 하위 할 일과 함께 목록에서 빠진다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.text('보고서'));
    await tapVisible(tester, find.byType(TodoGroupField));
    await tapVisible(tester, find.widgetWithText(ListTile, '학습'));
    await tapVisible(tester, find.widgetWithText(FilledButton, '수정'));

    expect(todos.updated.single.$2.todoGroupId, 'group-study');
    expect(find.text('보고서'), findsNothing);
    expect(find.text('회의 준비'), findsOneWidget);
    expect(find.text("'학습' 할 일 그룹으로 옮겼습니다"), findsOneWidget);
    expect(todos.readGroupIds.last, ['group-work']);
    expect(
      [
        for (final t in await todos.readTodosV1TodosGet(
          todoGroupIds: ['group-work'],
        ))
          t.title,
      ],
      ['회의 준비'],
    );
  });

  testWidgets('할 일이 없으면 안내를 보이고 첫 할 일 추가하기는 이 그룹으로 만든다', (tester) async {
    todos.todos.removeWhere((t) => t.todoGroupId == 'group-work');
    await pumpPage(tester);

    expect(find.text('이 할 일 그룹에는 할 일이 없습니다'), findsOneWidget);
    await tapVisible(tester, find.text('첫 할 일 추가하기'));
    await tester.enterText(find.widgetWithText(TextFormField, '할 일 제목'), '정리');
    await tapVisible(tester, find.text('생성'));

    expect(todos.created.single.todoGroupId, 'group-work');
  });

  testWidgets('할 일을 불러오지 못하면 오류를 보이고 대시보드로 갈 수 있다', (tester) async {
    todos.readError = Exception('끊김');
    await pumpPage(tester);

    expect(find.text('할 일을 불러오지 못했습니다'), findsOneWidget);
    await tapVisible(tester, find.text('대시보드로'));
    expect(location(), AppRoute.todo.path);
  });

  testWidgets('할 일을 불러오지 못한 뒤 다시 시도하면 목록을 그린다', (tester) async {
    todos.readError = Exception('끊김');
    await pumpPage(tester);

    todos.readError = null;
    await tapVisible(tester, find.text('다시 시도'));
    expect(find.text('보고서'), findsOneWidget);
  });

  group('할 일 그룹 설정', () {
    Future<void> openSettings(WidgetTester tester) =>
        tapVisible(tester, find.byTooltip('할 일 그룹 설정'));

    testWidgets('수정은 그룹 값으로 채운 시트를 열고, 바꾼 이름이 제목에 보인다', (tester) async {
      await pumpPage(tester);
      await openSettings(tester);
      await tapVisible(tester, find.text('할 일 그룹 수정'));

      expect(find.widgetWithText(TextFormField, '회사 일'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, '업무'), '회사');
      await tapVisible(tester, find.widgetWithText(FilledButton, '수정'));

      expect(todos.updatedGroups.single.$1, 'group-work');
      expect(find.text('회사'), findsOneWidget);
    });

    testWidgets('삭제 확인창은 할 일이 기본 그룹으로 옮겨진다고 알리고, 확인하면 지운 뒤 대시보드로 간다', (
      tester,
    ) async {
      await pumpPage(tester);
      await openSettings(tester);
      await tapVisible(tester, find.text('할 일 그룹 삭제'));

      expect(find.textContaining('기본 할 일 그룹으로 옮겨집니다'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(todos.deletedGroups, ['group-work']);
      expect(location(), AppRoute.todo.path);
      expect(find.text('업무 할 일 그룹이 삭제되었습니다'), findsOneWidget);
    });

    testWidgets('삭제를 취소하면 지우지 않고 머문다', (tester) async {
      await pumpPage(tester);
      await openSettings(tester);
      await tapVisible(tester, find.text('할 일 그룹 삭제'));
      await tapVisible(tester, find.widgetWithText(TextButton, '취소'));

      expect(todos.deletedGroups, isEmpty);
      expect(location(), '/todo/group-work');
    });

    testWidgets('삭제에 실패하면 알리고 머문다', (tester) async {
      todos.writeError = Exception('서버 오류');
      await pumpPage(tester);
      await openSettings(tester);
      await tapVisible(tester, find.text('할 일 그룹 삭제'));
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));

      expect(find.textContaining('할 일 그룹 삭제에 실패했습니다'), findsOneWidget);
      expect(location(), '/todo/group-work');
    });

    testWidgets('기본 그룹은 수정만 있고 삭제가 없다', (tester) async {
      await pumpPage(tester, groupId: defaultTodoGroupId);
      await openSettings(tester);

      expect(find.text('할 일 그룹 수정'), findsOneWidget);
      expect(find.text('할 일 그룹 삭제'), findsNothing);
    });
  });
}
