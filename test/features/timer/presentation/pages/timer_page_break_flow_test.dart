import 'dart:async';

import 'package:momeet/core/providers/retry_policy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard.dart';
import 'package:momeet/features/timer/presentation/widgets/digital_clock.dart';
import 'package:momeet/features/timer/presentation/widgets/current_task_display.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';
import '../../../../helpers/timer_gallery_finders.dart';

/// 휴식 중에 타이머를 실행하는 버튼을 누르는 흐름. 실제 TimerController로 보낸 요청까지 본다
///
/// 휴식 버튼 자체와 휴식 provider 규칙은 timer_page_test.dart, break_timer_provider_test.dart
void main() {
  final clock = DateTime.utc(2026, 11, 9, 10, 10);

  // 10:00에 시작해 10분 센 뒤 일시정지한 A(15분 남음), 10:05에 시작해 5분 센 뒤 일시정지한 B(20분 남음)
  final pausedA = makeTimer(
    id: 'a',
    status: TimerStatus.paused,
    startedAt: DateTime.utc(2026, 11, 9, 10),
    createdAt: DateTime.utc(2026, 11, 9, 9, 30),
    allocatedDuration: 25 * 60,
    elapsedTime: 10 * 60,
  ).copyWith(title: 'A 작업');
  final pausedB = makeTimer(
    id: 'b',
    status: TimerStatus.paused,
    startedAt: DateTime.utc(2026, 11, 9, 10, 5),
    createdAt: DateTime.utc(2026, 11, 9, 9),
    allocatedDuration: 25 * 60,
    elapsedTime: 5 * 60,
  ).copyWith(title: 'B 작업');
  // 25분을 다 센 시간 종료 타이머
  final expiredA = pausedA.copyWith(elapsedTime: 25 * 60);

  const wide = Size(1024, 800);
  const narrow = Size(400, 800);

  late FakeTimerRepository repository;

  /// 서버가 가진 타이머. 명령 응답이 이 값을 바꾼다
  late Map<String, TimerRead> server;

  /// [timers]를 서버의 활성 타이머로 둔 리포지토리. 명령 응답은 그 타이머의 상태를 바꾸고,
  /// 늘리기(PATCH)는 보낸 allocated_duration을, 만들기는 보낸 제목·할 일로 새 타이머 `c`를 둔다
  FakeTimerRepository serve(List<TimerRead> timers) {
    server = {for (final timer in timers) timer.id: timer};
    final repo = FakeTimerRepository()
      ..listActive = () async => server.values.toList();
    repo.respond = (timerId, status) {
      final held = server[timerId]!;
      final update = repo.calls.last == 'update:$timerId' ? repo.updated : null;
      return server[timerId] = held.copyWith(
        status: status,
        allocatedDuration: update?.allocatedDuration ?? held.allocatedDuration,
        startedAt: status == TimerStatus.running ? clock : held.startedAt,
        updatedAt: clock,
      );
    };
    repo.createResponse = (data) => server['c'] = makeTimer(
      id: 'c',
      status: TimerStatus.running,
      startedAt: clock,
      allocatedDuration: data.allocatedDuration,
    ).copyWith(title: data.title, todoId: data.todoId, updatedAt: clock);
    return repo;
  }

  List<Override> overrides({List<TodoRead> todos = const []}) => [
    allTodosProvider.overrideWith((ref) async => todos),
    timerFriendActivityProvider.overrideWith(
      (ref) => const Stream<TimerWsTimerEvent>.empty(),
    ),
    timerRepositoryProvider.overrideWithValue(repository),
    timerWsClientProvider.overrideWithValue(null),
    currentUserProvider.overrideWithValue(null),
    serverClockProvider.overrideWithValue(ServerClock(deviceNow: () => clock)),
    // 타이머 목록은 읽을 때의 서버 타이머다
    timerHistoryProvider.overrideWith(
      (ref) async => sortTimerHistory(server.values.toList()),
    ),
    timerTickerProvider.overrideWith((ref) {
      final active = ref.watch(activeTimerProvider).value;
      return Stream.value(
        active == null ? Duration.zero : displayRemaining(active, clock),
      );
    }),
  ];

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// [timers]를 서버의 활성 타이머로 두고 타이머 화면을 [size]로 그린다
  Future<void> pumpPage(
    WidgetTester tester,
    List<TimerRead> timers, {
    Size size = wide,
  }) async {
    setSize(tester, size);
    repository = serve(timers);
    await tester.pumpWidget(
      ProviderScope(
        retry: appRetry,
        overrides: overrides(),
        child: const MaterialApp(home: TimerPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  BreakSession? breakSession(WidgetTester tester) =>
      container(tester).read(breakTimerProvider);

  Finder inDashboard(Finder finder) =>
      find.descendant(of: find.byType(TimerDashboard), matching: finder);

  Finder fab(IconData icon) => find.ancestor(
    of: find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byIcon(icon),
    ),
    matching: find.byType(FloatingActionButton),
  );

  /// 대시보드의 작업 제목
  Finder title(String text) => find.descendant(
    of: find.byType(CurrentTaskDisplay),
    matching: find.text(text),
  );

  String? clockText(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byType(DigitalClock),
          matching: find.byType(Text),
        ),
      )
      .data;

  Finder listButton(String timerId, String tooltip) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is TimerHistoryItem && widget.timer.id == timerId,
    ),
    matching: find.byTooltip(tooltip),
  );

  /// 대시보드가 보이는 타이머에서 휴식을 시작한다
  Future<void> startBreak(WidgetTester tester) async {
    await tester.tap(fab(Icons.coffee));
    await tester.pumpAndSettle();
    expect(breakSession(tester), isNotNull);
    expect(inDashboard(find.text('휴식')), findsOneWidget);
  }

  /// 좁은 화면이면 앱 바에서 타이머 목록 시트를 연다
  Future<void> openList(WidgetTester tester, Size size) async {
    if (size == wide) return;
    await tester.tap(find.byTooltip('타이머 목록'));
    await tester.pumpAndSettle();
  }

  /// 휴식이 끝나 대시보드가 실행 중인 [name] 타이머와 일시정지 버튼을 보인다
  void expectRunning(WidgetTester tester, String name) {
    expect(breakSession(tester), isNull);
    expect(inDashboard(find.text('휴식')), findsNothing);
    expect(fab(Icons.stop), findsNothing);
    expect(title(name), findsOneWidget);
    expect(fab(Icons.pause), findsOneWidget);
    expect(fab(Icons.play_arrow), findsNothing);
  }

  for (final (layout, size) in [('넓은 화면 목록', wide), ('좁은 화면 목록 시트', narrow)]) {
    group('$layout에서', () {
      testWidgets('휴식을 시작한 일시정지 타이머를 재개하면 휴식이 끝나고 그 타이머가 실행된다', (tester) async {
        await pumpPage(tester, [pausedA], size: size);
        await startBreak(tester);

        await openList(tester, size);
        await tester.tap(listButton('a', '재개'));
        await tester.pumpAndSettle();

        expect(repository.calls, ['list', 'resume:a']);
        expectRunning(tester, 'A 작업');
        expect(clockText(tester), '00:15:00');
      });

      testWidgets('재개가 실패하면 휴식은 끝난 채로 두고 실패를 알리며 타이머는 일시정지로 돌아간다', (
        tester,
      ) async {
        await pumpPage(tester, [pausedA], size: size);
        await startBreak(tester);
        final gate = Completer<void>();
        repository
          ..gate = gate.future
          ..error = Exception('서버 오류');

        await openList(tester, size);
        await tester.tap(listButton('a', '재개'));
        await tester.pump();

        // 응답 전에 실행 중으로 먼저 보이므로 휴식이 끝난다
        expect(repository.calls, ['list', 'resume:a']);
        expectRunning(tester, 'A 작업');

        gate.complete();
        await tester.pumpAndSettle();

        expect(repository.calls, ['list', 'resume:a']);
        expect(find.text('재개 실패: Exception: 서버 오류'), findsOneWidget);
        expect(breakSession(tester), isNull);
        expect(inDashboard(find.text('휴식')), findsNothing);
        expect(title('A 작업'), findsOneWidget);
        expect(inDashboard(find.text('일시정지')), findsOneWidget);
        expect(fab(Icons.play_arrow), findsOneWidget);
        expect(fab(Icons.coffee), findsOneWidget);
        expect(listButton('a', '재개'), findsOneWidget);
      });

      testWidgets(
        '휴식을 시작한 시간 종료 타이머를 5분 연장하면 늘린 뒤 재개하고 휴식이 끝나 5분 남은 실행 중으로 보인다',
        (tester) async {
          await pumpPage(tester, [expiredA], size: size);
          expect(inDashboard(find.text('시간 종료')), findsOneWidget);
          await startBreak(tester);

          await openList(tester, size);
          await tester.tap(listButton('a', '5분 연장'));
          await tester.pumpAndSettle();

          expect(repository.calls, ['list', 'update:a', 'resume:a']);
          expect(repository.updated?.allocatedDuration, 30 * 60);
          expectRunning(tester, 'A 작업');
          expect(inDashboard(find.text('시간 종료')), findsNothing);
          expect(clockText(tester), '00:05:00');
        },
      );
    });
  }

  testWidgets('재개가 실패한 뒤 목록에서 다시 재개하면 실행된다', (tester) async {
    await pumpPage(tester, [pausedA]);
    await startBreak(tester);
    repository.error = Exception('서버 오류');
    await tester.tap(listButton('a', '재개'));
    await tester.pumpAndSettle();
    expect(fab(Icons.play_arrow), findsOneWidget);

    repository.error = null;
    await tester.tap(listButton('a', '재개'));
    await tester.pumpAndSettle();

    expect(repository.calls, ['list', 'resume:a', 'resume:a']);
    expectRunning(tester, 'A 작업');
  });

  group('두 일시정지 타이머', () {
    testWidgets('A에서 휴식을 시작하고 목록에서 B를 재개하면 휴식이 끝나고 B를 보이며 A는 일시정지로 남는다', (
      tester,
    ) async {
      // 최근에 시작한 A를 기본으로 보인다
      final recentA = pausedA.copyWith(
        startedAt: DateTime.utc(2026, 11, 9, 10, 6),
      );
      await pumpPage(tester, [recentA, pausedB]);
      expect(title('A 작업'), findsOneWidget);
      await startBreak(tester);

      await tester.tap(listButton('b', '재개'));
      await tester.pumpAndSettle();

      expect(repository.calls, ['list', 'resume:b']);
      expectRunning(tester, 'B 작업');
      expect(shownTimerPage(tester), 'b');
      expect(listButton('a', '재개'), findsOneWidget);
      expect(listButton('b', '일시정지'), findsOneWidget);
    });

    testWidgets('넘겨 고른 A에서 휴식을 시작하고 목록에서 B를 재개하면 휴식이 끝나고 대시보드는 재개한 B로 넘어간다', (
      tester,
    ) async {
      await pumpPage(tester, [pausedA, pausedB]);
      await swipeTimerGallery(tester, forward: true);
      expect(shownTimerPage(tester), 'a');
      expect(title('A 작업'), findsOneWidget);
      await startBreak(tester);

      await tester.tap(listButton('b', '재개'));
      await tester.pumpAndSettle();

      expect(repository.calls, ['list', 'resume:b']);
      expect(breakSession(tester), isNull);
      expect(inDashboard(find.text('휴식')), findsNothing);
      expectRunning(tester, 'B 작업');
      expect(shownTimerPage(tester), 'b');
      // B가 실행 중이므로 휴식을 다시 시작할 수 없다
      expect(fab(Icons.coffee), findsNothing);
      expect(listButton('a', '재개'), findsOneWidget);

      await swipeTimerGallery(tester, forward: true);
      expect(title('A 작업'), findsOneWidget);
      expect(inDashboard(find.text('일시정지')), findsOneWidget);
      expect(fab(Icons.play_arrow), findsOneWidget);
    });
  });

  group('휴식 중 대시보드', () {
    testWidgets('일시정지 타이머에서 시작한 휴식 중에는 갤러리·새 타이머·재개 버튼이 없고 목록의 재개만 남는다', (
      tester,
    ) async {
      await pumpPage(tester, [pausedA, pausedB]);
      expect(timerGallery(), findsOneWidget);
      await startBreak(tester);

      expect(timerGallery(), findsNothing);
      expect(timerPage('a'), findsNothing);
      expect(timerPage('b'), findsNothing);
      expect(find.widgetWithText(ActionChip, '새 타이머'), findsNothing);
      expect(fab(Icons.play_arrow), findsNothing);
      expect(fab(Icons.stop), findsOneWidget);
      expect(listButton('a', '재개'), findsOneWidget);
      expect(listButton('b', '재개'), findsOneWidget);
      expect(repository.calls, ['list']);
    });

    testWidgets('대기 상태에서 시작한 휴식 중에는 새 작업 시작 버튼이 없다', (tester) async {
      await pumpPage(tester, []);
      await tester.tap(
        find
            .descendant(
              of: find.byWidgetPredicate((widget) => widget is SegmentedButton),
              matching: find.text('휴식'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await startBreak(tester);

      expect(find.widgetWithText(ActionChip, '새 타이머'), findsNothing);
      expect(fab(Icons.play_arrow), findsNothing);
      expect(fab(Icons.stop), findsOneWidget);
      expect(repository.calls, ['list']);
    });
  });

  // 앱처럼 탭 셸에 두면 타이머 화면이 화면 밖에 남고, 경로만 두면 할 일 화면에 있는 동안 타이머 화면이 없다
  for (final shell in [true, false]) {
    group('할 일 화면에서 시작 (${shell ? '탭 셸' : '타이머 화면 없음'})', () {
      final todo = makeTodo().copyWith(title: '보고서 쓰기');

      late GoRouter router;

      /// 타이머 화면과 할 일 타일 화면을 오가는 라우터로 그린다. 타이머 화면에서 시작한다
      Future<void> pumpRouter(
        WidgetTester tester,
        List<TimerRead> timers,
      ) async {
        setSize(tester, wide);
        repository = serve(timers);
        final tree = buildTodoTree([todo]);
        Widget todoScreen() => Scaffold(
          body: ListView(
            children: [
              EditableTodoTreeTile(
                node: tree.nodeMap[todo.id]!,
                tree: tree,
                initiallyExpanded: true,
              ),
            ],
          ),
        );
        final timerRoute = GoRoute(
          path: AppRoute.timer.path,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TimerPage()),
        );
        final todoRoute = GoRoute(
          path: AppRoute.todo.path,
          pageBuilder: (context, state) =>
              NoTransitionPage(child: todoScreen()),
        );
        router = GoRouter(
          initialLocation: AppRoute.timer.path,
          routes: shell
              ? [
                  StatefulShellRoute.indexedStack(
                    builder: (context, state, navigationShell) =>
                        navigationShell,
                    branches: [
                      StatefulShellBranch(routes: [todoRoute]),
                      StatefulShellBranch(routes: [timerRoute]),
                    ],
                  ),
                ]
              : [todoRoute, timerRoute],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            retry: appRetry,
            overrides: [
              ...overrides(todos: [todo]),
              todoTimerAggregationsProvider.overrideWith((ref) async => {}),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();
      }

      /// 할 일 화면으로 가서 타일의 '타이머 시작'으로 기본값 그대로 시작하고 '타이머 보기'로 돌아온다
      Future<void> startFromTile(WidgetTester tester) async {
        router.go(AppRoute.todo.path);
        await tester.pumpAndSettle();
        expect(find.byType(TimerPage), findsNothing);

        await tester.tap(find.byTooltip('타이머 시작'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, '시작'));
        await tester.pumpAndSettle();

        expect(repository.calls, ['list', 'create']);
        expect(repository.created?.todoId, todo.id);
        expect(breakSession(tester), isNull);

        await tester.tap(find.text('타이머 보기'));
        await tester.pumpAndSettle();
        expect(find.byType(TimerPage), findsOneWidget);
      }

      /// 1초마다 내는 할 일 타일의 남은 시간 스트림을 멈춘다
      Future<void> unmount(WidgetTester tester) async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }

      testWidgets('대기 상태의 휴식 중에 할 일 타일에서 시작하면 타이머 화면에 휴식 없이 그 타이머가 실행 중이다', (
        tester,
      ) async {
        await pumpRouter(tester, []);
        await tester.tap(
          find
              .descendant(
                of: find.byWidgetPredicate(
                  (widget) => widget is SegmentedButton,
                ),
                matching: find.text('휴식'),
              )
              .first,
        );
        await tester.pumpAndSettle();
        await startBreak(tester);

        await startFromTile(tester);

        expect(repository.calls, ['list', 'create']);
        expectRunning(tester, '보고서 쓰기');
        expect(clockText(tester), '00:25:00');
        await unmount(tester);
      });

      testWidgets('일시정지 타이머에서 시작한 휴식 중에 할 일 타일에서 시작하면 새 타이머를 고른 채 실행 중이다', (
        tester,
      ) async {
        await pumpRouter(tester, [pausedA]);
        await startBreak(tester);

        await startFromTile(tester);

        expect(repository.calls, ['list', 'create']);
        expectRunning(tester, '보고서 쓰기');
        expect(shownTimerPage(tester), 'c');
        expect(listButton('a', '재개'), findsOneWidget);
        await unmount(tester);
      });
    });
  }
}
