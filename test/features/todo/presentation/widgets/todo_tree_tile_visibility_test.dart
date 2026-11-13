import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:momeet/features/todo/presentation/pages/todo_group_detail_page.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/providers/friend_providers.dart';
import 'package:momeet/shared/ui/ui.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 할 일 그룹 화면의 할 일 줄에 있는 공유 설정 버튼
void main() {
  late FakeTodosClient todos;
  late FakeVisibilityClient visibility;

  TodoRead todo(
    String id,
    String title, {
    String? parentId,
    DateTime? deadline,
    VisibilityLevel? level,
  }) => TodoRead(
    id: id,
    title: title,
    todoGroupId: 'group-work',
    parentId: parentId,
    deadline: deadline,
    status: TodoStatus.unscheduled,
    createdAt: DateTime.utc(2026, 1, 1),
    visibilityLevel: level,
  );

  setUp(() {
    todos = FakeTodosClient(
      [
        todo('todo-1', '보고서'),
        todo('todo-2', '자료 조사', parentId: 'todo-1'),
        todo('todo-3', '회의 준비', deadline: DateTime.utc(2026, 5, 1)),
        todo('todo-4', '발표', level: VisibilityLevel.selected),
      ],
      [makeTodoGroup(id: 'group-work', name: '업무')],
    );
    visibility = FakeVisibilityClient()
      ..onWrite = (type, id, level) {
        final index = todos.todos.indexWhere((t) => t.id == id);
        todos.todos[index] = todos.todos[index].copyWith(
          visibilityLevel: level,
        );
      };
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: [
          todosApiProvider.overrideWithValue(todos),
          tagsApiProvider.overrideWithValue(FakeTagsClient()),
          visibilityApiProvider.overrideWithValue(visibility),
          activeTimersProvider.overrideWith((ref) async => const []),
          todoTimerAggregationsProvider.overrideWith((ref) async => const {}),
          friendsProvider.overrideWith(
            (ref) async => [makeFriend('friend-1', displayName: '영희')],
          ),
        ],
        child: const MaterialApp(
          home: TodoGroupDetailPage(groupId: 'group-work'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// [title] 할 일 줄의 공유 설정 버튼
  Finder shareButton(String title) => find.descendant(
    of: find
        .ancestor(of: find.text(title), matching: find.byType(InkWell))
        .first,
    matching: find.byTooltip('공유 설정'),
  );

  IconData? shareIcon(WidgetTester tester, String title) => tester
      .widget<Icon>(
        find.descendant(of: shareButton(title), matching: find.byType(Icon)),
      )
      .icon;

  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('할 일 줄마다 지금 공유 범위를 타이머와 같은 아이콘으로 보인다', (tester) async {
    await pumpPage(tester);

    expect(shareIcon(tester, '보고서'), Icons.lock_outline);
    expect(shareIcon(tester, '발표'), Icons.how_to_reg_outlined);
  });

  testWidgets('누르면 그 할 일의 설정을 읽어 네 범위를 고르는 시트를 연다', (tester) async {
    await pumpPage(tester);
    await tester.tap(shareButton('회의 준비'));
    await tester.pumpAndSettle();

    expect(visibility.calls, ['get:todo/todo-3']);
    expect(
      tester
          .widgetList<RadioListTile<VisibilityLevel>>(
            find.byType(RadioListTile<VisibilityLevel>),
          )
          .map((tile) => tile.value),
      [
        VisibilityLevel.private,
        VisibilityLevel.friends,
        VisibilityLevel.selected,
        VisibilityLevel.allowedEmails,
      ],
    );
  });

  testWidgets('마감이 있으면 마감 일정은 함께 공유되지 않는다고 알린다', (tester) async {
    await pumpPage(tester);
    await tester.tap(shareButton('회의 준비'));
    await tester.pumpAndSettle();

    expect(
      find.text('마감 일정은 함께 공유되지 않습니다. 캘린더의 일정에서 따로 공유합니다.'),
      findsOneWidget,
    );
  });

  testWidgets('하위 할 일이 있으면 함께 공유되지 않는다고 알린다', (tester) async {
    await pumpPage(tester);
    await tester.tap(shareButton('보고서'));
    await tester.pumpAndSettle();

    expect(find.text('하위 할 일은 함께 공유되지 않습니다.'), findsOneWidget);
    expect(find.textContaining('마감 일정'), findsNothing);
  });

  testWidgets('알릴 것이 없으면 안내 없이 연다', (tester) async {
    await pumpPage(tester);
    await tester.tap(shareButton('발표'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(AppHintCard),
      ),
      findsNothing,
    );
  });

  testWidgets('저장하면 보내고 그 줄의 아이콘이 새 범위로 바뀐다', (tester) async {
    await pumpPage(tester);
    await tester.tap(shareButton('보고서'));
    await tester.pumpAndSettle();
    await tapInSheet(
      tester,
      find.widgetWithText(RadioListTile<VisibilityLevel>, '친구 공개'),
    );
    await tapInSheet(tester, find.widgetWithText(FilledButton, '저장'));

    expect(visibility.calls, ['get:todo/todo-1', 'put:todo/todo-1']);
    expect(find.byType(BottomSheet), findsNothing);
    expect(shareIcon(tester, '보고서'), Icons.group_outlined);
    expect(shareIcon(tester, '회의 준비'), Icons.lock_outline);
  });
}
