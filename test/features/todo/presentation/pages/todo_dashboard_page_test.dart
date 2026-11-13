import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/pages/todo_dashboard_page.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_card.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTodosClient todos;

  setUp(() {
    todos = FakeTodosClient(const [], [
      makeTodoGroup(id: 'group-study', name: '학습'),
      makeTodoGroup(id: 'group-work', name: '업무', description: '회사 일'),
    ]);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoute.todo.path,
      routes: [
        GoRoute(
          path: AppRoute.todo.path,
          name: AppRoute.todo.name,
          builder: (context, state) => const TodoDashboardPage(),
          routes: [
            GoRoute(
              path: ':groupId',
              name: AppRoute.todoGroupDetail.name,
              builder: (context, state) =>
                  Text('그룹 화면 ${state.pathParameters['groupId']}'),
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
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('받은 순서(기본 그룹 먼저)대로 카드로 보이고, 누르면 그 그룹 화면으로 간다', (tester) async {
    await pumpPage(tester);

    expect(find.byType(TodoGroupCard), findsNWidgets(3));
    double left(String name) => tester.getTopLeft(find.text(name)).dx;
    expect(left('기본'), lessThan(left('업무')));
    expect(left('업무'), lessThan(left('학습')));
    expect(find.text('회사 일'), findsOneWidget);

    await tapVisible(tester, find.text('학습'));
    expect(find.text('그룹 화면 group-study'), findsOneWidget);
  });

  testWidgets('할 일 추가는 기본 그룹에 할 일을 만든다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byType(FloatingActionButton));
    expect(find.text('새 할 일 만들기'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '할 일 제목'), '정리');
    await tapVisible(tester, find.text('생성'));

    expect(todos.created.single.title, '정리');
    expect(todos.created.single.todoGroupId, defaultTodoGroupId);
  });

  testWidgets('그룹 목록을 받지 못해도 할 일 추가는 그룹 없이 보낸다', (tester) async {
    todos.groupsReadError = Exception('끊김');
    await pumpPage(tester);
    await tapVisible(tester, find.byType(FloatingActionButton));
    await tester.enterText(find.widgetWithText(TextFormField, '할 일 제목'), '정리');
    await tapVisible(tester, find.text('생성'));

    expect(todos.created.single.todoGroupId, isNull);
  });

  testWidgets('새 할 일 그룹 카드로 만든 그룹이 카드로 나타난다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.text('새 해야 할 일 목록'));
    expect(find.text('새 해야 할 일 목록 만들기'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '해야 할 일 목록 이름'),
      '운동',
    );
    await tapVisible(tester, find.text('생성'));

    expect(todos.createdGroups.single.name, '운동');
    expect(find.byType(TodoGroupCard), findsNWidgets(4));
    expect(find.text('운동'), findsOneWidget);
  });

  testWidgets('불러오지 못하면 오류를 보이고 다시 시도하면 카드를 그린다', (tester) async {
    todos.groupsReadError = Exception('끊김');
    await pumpPage(tester);

    expect(find.text('해야 할 일 목록을 불러오지 못했습니다'), findsOneWidget);
    todos.groupsReadError = null;
    await tapVisible(tester, find.text('다시 시도'));
    expect(find.byType(TodoGroupCard), findsNWidgets(3));
  });
}
