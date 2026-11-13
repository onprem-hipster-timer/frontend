import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/todo/presentation/pages/shared_todos_page.dart';
import 'package:momeet/features/todo/presentation/pages/todo_dashboard_page.dart';
import 'package:momeet/features/todo/presentation/pages/todo_group_detail_page.dart';
import 'package:momeet/features/todo/presentation/pages/todo_picker_page.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 공유받은 할 일: 대시보드의 입구, 보기만 하는 목록, 내 목록과 섞이지 않음
void main() {
  late FakeTodosClient todos;
  late GoRouter router;

  TodoRead todo(
    String id,
    String title, {
    String group = 'group-work',
    String? parentId,
    String? ownerId,
  }) => TodoRead(
    id: id,
    title: title,
    todoGroupId: group,
    parentId: parentId,
    status: TodoStatus.unscheduled,
    createdAt: DateTime.utc(2026, 1, 1),
    ownerId: ownerId ?? 'me',
    isShared: ownerId != null,
  );

  final mine = [todo('mine-1', '내 보고서'), todo('mine-2', '내 회의 준비')];
  final shared = [
    todo('y-1', '영희 발표 준비', group: 'y-group', ownerId: 'friend-1'),
    todo(
      'y-2',
      '영희 자료 조사',
      group: 'y-group',
      parentId: 'y-1',
      ownerId: 'friend-1',
    ),
    // 내 그룹과 id가 같아도 내 그룹에 섞이지 않는다
    todo('c-1', '철수 운동', ownerId: 'friend-2'),
    todo('s-1', '모르는 사람 일', group: 's-group', ownerId: 'stranger'),
  ];

  setUp(() {
    todos = FakeTodosClient(
      [...mine, ...shared],
      [makeTodoGroup(id: 'group-work', name: '업무')],
    );
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String initialLocation = '/todo',
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoute.todo.path,
          name: AppRoute.todo.name,
          builder: (context, state) => const TodoDashboardPage(),
          routes: [
            GoRoute(
              path: 'shared',
              name: AppRoute.sharedTodos.name,
              builder: (context, state) => const SharedTodosPage(),
            ),
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
          tagsApiProvider.overrideWithValue(FakeTagsClient()),
          activeTimersProvider.overrideWith((ref) async => const []),
          todoTimerAggregationsProvider.overrideWith((ref) async => const {}),
          friendsProvider.overrideWith(
            (ref) async => [
              makeFriend('friend-1', displayName: '영희'),
              makeFriend('friend-2', displayName: '철수'),
            ],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder entry() => find.widgetWithText(ListTile, '공유받은 할 일');

  group('대시보드', () {
    testWidgets('공유받은 할 일이 있으면 개수를 보이고 누르면 그 화면으로 간다', (tester) async {
      await pumpApp(tester);

      expect(todos.readScopes, contains(ResourceScope.shared));
      expect(
        find.descendant(of: entry(), matching: find.text('4개')),
        findsOneWidget,
      );

      await tester.tap(entry());
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/todo/shared',
      );
      expect(find.text('영희 발표 준비'), findsOneWidget);
    });

    testWidgets('공유받은 할 일이 없으면 입구를 두지 않는다', (tester) async {
      todos.todos.removeWhere((t) => t.isShared);

      await pumpApp(tester);

      expect(entry(), findsNothing);
      expect(find.text('업무'), findsOneWidget);
    });

    testWidgets('공유받은 할 일을 읽지 못하면 입구를 두지 않고 그룹은 보인다', (tester) async {
      todos
        ..readError = Exception('네트워크 오류')
        ..groupsReadError = null;

      await pumpApp(tester);
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(entry(), findsNothing);
      expect(find.text('업무'), findsOneWidget);
    });
  });

  group('공유받은 할 일 화면', () {
    testWidgets('공유한 사람별로 묶고 이름을 보이며, 공유된 상위·하위는 트리로 잇는다', (tester) async {
      await pumpApp(tester, initialLocation: '/todo/shared');

      expect(find.text('공유받은 할 일은 보기만 할 수 있습니다'), findsOneWidget);
      expect(find.text('영희님이 공유'), findsOneWidget);
      expect(find.text('철수님이 공유'), findsOneWidget);
      expect(find.text('공유받음'), findsOneWidget);

      final parent = tester.getTopLeft(find.text('영희 발표 준비'));
      final child = tester.getTopLeft(find.text('영희 자료 조사'));
      expect(child.dy, greaterThan(parent.dy));
      expect(child.dx, greaterThan(parent.dx));

      // 공유한 사람 이름 아래에 그 사람의 할 일이 온다
      expect(
        tester.getTopLeft(find.text('철수 운동')).dy,
        greaterThan(tester.getTopLeft(find.text('철수님이 공유')).dy),
      );
    });

    testWidgets('상태 바꾸기·수정·삭제·타이머·공유 설정·끌기를 두지 않는다', (tester) async {
      await pumpApp(tester, initialLocation: '/todo/shared');

      expect(find.text('수정'), findsNothing);
      expect(find.text('삭제'), findsNothing);
      expect(find.byTooltip('타이머 시작'), findsNothing);
      expect(find.byTooltip('공유 설정'), findsNothing);
      expect(find.byType(TodoStatusSelector), findsNothing);
      expect(find.byType(LongPressDraggable<TodoRead>), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('읽지 못하면 알리고 다시 시도로 읽는다', (tester) async {
      todos
        ..readError = Exception('네트워크 오류')
        ..readFailures = 1;

      await pumpApp(tester, initialLocation: '/todo/shared');
      expect(find.text('공유받은 할 일을 불러오지 못했습니다'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '다시 시도'));
      await tester.pumpAndSettle();

      expect(find.text('영희 발표 준비'), findsOneWidget);
    });

    testWidgets('공유받은 할 일이 없어지면 없다고 알린다', (tester) async {
      todos.todos.removeWhere((t) => t.isShared);

      await pumpApp(tester, initialLocation: '/todo/shared');

      expect(find.text('공유받은 할 일이 없습니다'), findsOneWidget);
    });
  });

  group('내 목록', () {
    testWidgets('할 일 그룹 화면은 내 할 일만 보인다', (tester) async {
      await pumpApp(tester, initialLocation: '/todo/group-work');

      expect(todos.readScopes, everyElement(isNot(ResourceScope.shared)));
      expect(find.text('내 보고서'), findsOneWidget);
      expect(find.text('철수 운동'), findsNothing);
    });

    testWidgets('할 일 고르기도 내 할 일만 보인다', (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: appRetry,
          overrides: [
            todosApiProvider.overrideWithValue(todos),
            tagsApiProvider.overrideWithValue(FakeTagsClient()),
          ],
          child: MaterialApp(home: TodoPickerPage(selectable: (_) => true)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('내 보고서'), findsOneWidget);
      for (final title in ['영희 발표 준비', '철수 운동', '모르는 사람 일']) {
        expect(find.text(title), findsNothing, reason: title);
      }
    });
  });
}
