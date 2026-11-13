import 'dart:async';

import 'package:dio/dio.dart' show RequestOptions;
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:momeet/core/providers/retry_policy.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/sheet_host.dart';
import 'package:momeet/shared/domain/terms.dart';

/// '할 일로 변환' 버튼
final _convertLabel = '${Terms.todo.withJosa('으로', '로')} 변환';

/// '연결된 할 일 보기' 버튼
final _linkedTodoLabel = '연결된 ${Terms.todo} 보기';

/// 할 일 하나 읽기를 [gate]가 끝날 때까지 붙잡는 가짜 클라이언트. 읽은 횟수를 센다
class _GatedTodosClient extends FakeTodosClient {
  _GatedTodosClient(super.todos);

  final gate = Completer<void>();
  var reads = 0;

  @override
  Future<TodoRead> readTodoV1TodosTodoIdGet({
    required String todoId,
    String? timezone,
    RequestOptions? options,
  }) async {
    reads++;
    await gate.future;
    return super.readTodoV1TodosTodoIdGet(todoId: todoId);
  }
}

/// 일정 상세의 수정·할 일로 바꾸기·삭제·연결된 할 일로 가기
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  late FakeSchedulesClient schedules;
  late FakeTagsClient tags;
  late FakeTodosClient todos;
  late GoRouter router;

  ScheduleRead schedule({String? sourceTodoId}) => makeSchedule(
    id: 'schedule-1',
    title: '팀 회의',
    description: '주간 회의',
    sourceTodoId: sourceTodoId,
    startTime: DateTime.now().toUtc(),
    endTime: DateTime.now().add(const Duration(hours: 1)).toUtc(),
  );

  setUp(() {
    todos = FakeTodosClient([
      TodoRead(
        id: 'todo-1',
        title: '회의 준비',
        todoGroupId: 'group-study',
        status: TodoStatus.scheduled,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    ]);
    tags = FakeTagsClient([
      makeTagGroup(id: 'group-work', name: '업무'),
      makeTagGroup(id: 'group-study', name: '학습'),
    ]);
  });

  Future<void> pumpDetail(WidgetTester tester, ScheduleRead item) async {
    schedules = FakeSchedulesClient([item]);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/schedule'),
              child: const Text('달력 화면'),
            ),
          ),
        ),
        GoRoute(
          path: '/schedule',
          builder: (context, state) =>
              const ScheduleDetailPage(scheduleId: 'schedule-1'),
        ),
        GoRoute(
          path: AppRoute.todo.path,
          name: AppRoute.todo.name,
          builder: (context, state) => const Text('할 일 화면'),
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
          schedulesApiProvider.overrideWithValue(schedules),
          tagsApiProvider.overrideWithValue(tags),
          todosApiProvider.overrideWithValue(todos),
          scheduleTimersProvider(
            'schedule-1',
          ).overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
          locale: const Locale('ko', 'KR'),
        ),
      ),
    );
    await tester.tap(find.text('달력 화면'));
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('수정은 이 일정으로 채운 수정 시트를 연다', (tester) async {
    await pumpDetail(tester, schedule());
    await tapVisible(tester, find.text('수정'));

    expect(find.text('일정 수정'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '팀 회의'), findsOneWidget);
  });

  group('할 일로 바꾸기', () {
    testWidgets('그룹을 묻지 않고 바로 바꾸고(기본 할 일 그룹) 알린다', (tester) async {
      await pumpDetail(tester, schedule());
      await tapVisible(tester, find.text(_convertLabel));

      expect(schedules.convertedToTodo, [('schedule-1', null)]);
      expect(find.text('$_convertLabel되었습니다'), findsOneWidget);
    });

    testWidgets('실패하면 알린다', (tester) async {
      await pumpDetail(tester, schedule());
      schedules.writeError = Exception('서버 오류');
      await tapVisible(tester, find.text(_convertLabel));

      expect(find.textContaining('변환에 실패했습니다'), findsOneWidget);
    });
  });

  group('삭제', () {
    testWidgets('확인하면 지우고 이전 화면으로 돌아가 알린다', (tester) async {
      await pumpDetail(tester, schedule());
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));
      expect(find.textContaining('"팀 회의" 일정을 삭제하시겠습니까?'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제').last);

      expect(schedules.deleted.single.$1, 'schedule-1');
      expect(find.text('일정 상세'), findsNothing);
      expect(find.text('달력 화면'), findsOneWidget);
      expect(find.text('일정이 삭제되었습니다'), findsOneWidget);
    });

    testWidgets('취소하면 지우지 않고 머문다', (tester) async {
      await pumpDetail(tester, schedule());
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));
      await tapVisible(tester, find.widgetWithText(TextButton, '취소'));

      expect(schedules.deleted, isEmpty);
      expect(find.text('일정 상세'), findsOneWidget);
    });

    testWidgets('할 일 마감일에서 만든 일정이면 원본 할 일 처리를 묻고 고른 값을 보낸다', (tester) async {
      await pumpDetail(tester, schedule(sourceTodoId: 'todo-1'));
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제').last);
      await tapVisible(tester, find.text('마감일도 지우기'));

      expect(schedules.deleted.single.$2, SourceTodoPolicy.clearDeadline);
    });

    testWidgets('실패하면 알리고 머문다', (tester) async {
      await pumpDetail(tester, schedule());
      schedules.writeError = Exception('서버 오류');
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제'));
      await tapVisible(tester, find.widgetWithText(FilledButton, '삭제').last);

      expect(find.textContaining('삭제에 실패했습니다'), findsOneWidget);
      expect(find.text('일정 상세'), findsOneWidget);
    });
  });

  testWidgets('연결된 할 일 보기는 그 할 일이 있는 할 일 그룹으로 간다', (tester) async {
    await pumpDetail(tester, schedule(sourceTodoId: 'todo-1'));
    await tapVisible(tester, find.text(_linkedTodoLabel));

    expect(location(), '/todo/group-study');
    expect(find.text('그룹 화면 group-study'), findsOneWidget);
  });

  testWidgets('연결된 할 일을 받는 동안 버튼을 막고 진행을 보이며, 다시 눌러도 한 번만 간다', (tester) async {
    final gated = _GatedTodosClient(todos.todos);
    todos = gated;
    await pumpDetail(tester, schedule(sourceTodoId: 'todo-1'));
    Finder buttonOf(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    final button = buttonOf(_linkedTodoLabel);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
    expect(
      find.descendant(
        of: button,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<ButtonStyleButton>(buttonOf('삭제')).onPressed, isNull);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(gated.reads, 1);

    gated.gate.complete();
    await tester.pumpAndSettle();
    expect(location(), '/todo/group-study');
    expect(gated.reads, 1);
  });

  testWidgets('연결된 할 일을 받지 못하면 할 일 탭으로 간다', (tester) async {
    todos.readError = Exception('끊김');
    await pumpDetail(tester, schedule(sourceTodoId: 'todo-1'));
    await tapVisible(tester, find.text(_linkedTodoLabel));

    expect(location(), '/todo');
  });

  testWidgets('연결된 할 일이 지워져 없으면 할 일 탭으로 간다', (tester) async {
    await pumpDetail(tester, schedule(sourceTodoId: 'todo-gone'));
    await tapVisible(tester, find.text(_linkedTodoLabel));

    expect(location(), '/todo');
  });
}
