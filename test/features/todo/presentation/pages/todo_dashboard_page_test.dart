import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/pages/todo_dashboard_page.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_card.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';

void main() {
  late FakeTagsClient tags;

  setUp(() {
    tags = FakeTagsClient([
      makeTagGroup(id: 'group-work', name: '업무', description: '회사 일'),
      makeTagGroup(
        id: 'group-study',
        name: '학습',
        tags: [makeTag(groupId: 'group-study')],
      ),
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
        overrides: [tagsApiProvider.overrideWithValue(tags)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('그룹을 받은 순서대로 이름·설명 카드로 보이고, 누르면 그 그룹 화면으로 간다', (tester) async {
    await pumpPage(tester);

    expect(find.byType(TodoGroupCard), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('업무')).dx,
      lessThan(tester.getTopLeft(find.text('학습')).dx),
    );
    expect(find.text('회사 일'), findsOneWidget);

    await tapVisible(tester, find.text('학습'));
    expect(find.text('그룹 화면 group-study'), findsOneWidget);
  });

  testWidgets('그룹이 없으면 안내를 보이고 첫 그룹 만들기를 연다', (tester) async {
    tags.groups.clear();
    await pumpPage(tester);

    expect(find.text('그룹이 없습니다'), findsOneWidget);
    await tapVisible(tester, find.text('첫 그룹 만들기'));
    expect(find.text('새 그룹 만들기'), findsWidgets);
    expect(find.widgetWithText(TextFormField, '그룹 이름'), findsOneWidget);
  });

  testWidgets('새 그룹 만들기 버튼으로 만든 그룹이 카드로 나타난다', (tester) async {
    await pumpPage(tester);
    await tapVisible(tester, find.byType(FloatingActionButton));
    await tester.enterText(find.widgetWithText(TextFormField, '그룹 이름'), '운동');
    await tapVisible(tester, find.text('생성'));

    expect(find.byType(TodoGroupCard), findsNWidgets(3));
    expect(find.text('운동'), findsOneWidget);
  });

  testWidgets('불러오지 못하면 오류를 보이고 다시 시도하면 카드를 그린다', (tester) async {
    tags.readError = Exception('끊김');
    await pumpPage(tester);

    expect(find.text('그룹을 불러오지 못했습니다'), findsOneWidget);
    tags.readError = null;
    await tapVisible(tester, find.text('다시 시도'));
    expect(find.byType(TodoGroupCard), findsNWidgets(2));
  });
}
