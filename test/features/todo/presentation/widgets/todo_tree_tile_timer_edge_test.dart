import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree_tile.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 할 일 타일의 타이머 시작·남은 시간 경계. 기본 동작은 todo_tree_tile_timer_test.dart
void main() {
  late DateTime now;
  late List<TimerRead> active;
  late GoRouter router;

  setUp(() {
    now = DateTime.utc(2026, 11, 6, 10, 0, 30);
    active = [];
  });

  TodoRead todo({
    String id = 'todo-1',
    String title = '보고서 쓰기',
    String? parentId,
    TodoStatus status = TodoStatus.unscheduled,
    bool shared = false,
  }) => makeTodo(id: id).copyWith(
    title: title,
    parentId: parentId,
    status: status,
    isShared: shared,
  );

  /// [todoId]에 연결된 활성 타이머. 10:00에 시작했거나 그때까지 [elapsedTime]초를 센 타이머
  TimerRead activeTimer({
    String id = 'timer-1',
    String todoId = 'todo-1',
    TimerStatus status = TimerStatus.running,
    int allocatedDuration = 1500,
    int elapsedTime = 100,
  }) => makeTimer(
    id: id,
    status: status,
    startedAt: DateTime.utc(2026, 11, 6, 10),
    allocatedDuration: allocatedDuration,
    elapsedTime: elapsedTime,
  ).copyWith(todoId: todoId);

  /// 할 일 화면에 [todos]로 만든 트리에서 [rootId] 타일을 그린다. [expanded]는 펼쳐 둘 하위 할 일
  Future<void> pumpTile(
    WidgetTester tester,
    List<TodoRead> todos, {
    String rootId = 'todo-1',
    Set<String> expanded = const {},
    TimerController Function()? controller,
    List<Override> overrides = const [],
    bool liveActiveTimers = false,
  }) async {
    final tree = buildTodoTree(todos);
    router = GoRouter(
      initialLocation: AppRoute.todo.path,
      routes: [
        GoRoute(
          path: AppRoute.todo.path,
          builder: (context, state) => Scaffold(
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TodoTreeTile(
                    node: tree.nodeMap[rootId]!,
                    tree: tree,
                    initiallyExpanded: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.timer.path,
          builder: (context, state) => const Scaffold(body: Text('타이머 화면')),
        ),
        GoRoute(
          path: AppRoute.calendar.path,
          builder: (context, state) => const Scaffold(body: Text('달력 화면')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (controller != null)
            timerControllerProvider.overrideWith(controller),
          if (!liveActiveTimers)
            activeTimersProvider.overrideWith((ref) async => active),
          todoTimerAggregationsProvider.overrideWith((ref) async => {}),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => now),
          ),
          allTodosProvider.overrideWith((ref) async => todos),
          ...overrides,
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (expanded.isNotEmpty) {
      ProviderScope.containerOf(
        tester.element(find.byType(TodoTreeTile).first),
      ).read(expandedTodoIdsProvider.notifier).addAll(expanded);
    }
    await tester.pump();
    await tester.pump();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  /// 1초마다 내는 활성 타이머 스트림을 멈춘다
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  Finder startButton() => find.byTooltip('타이머 시작');
  Finder chip() => find.byType(ActionChip);
  Finder chipText(String text) =>
      find.descendant(of: chip(), matching: find.text(text));
  Finder tileOf(String id) => find.byWidgetPredicate(
    (widget) => widget is TodoTreeTile && widget.node.id == id,
  );

  /// 칩 안 [text]가 실제로 그려지는 색
  Color? renderedColor(WidgetTester tester, String text) => tester
      .widget<RichText>(
        find.descendant(of: chipText(text), matching: find.byType(RichText)),
      )
      .text
      .style
      ?.color;

  Color errorColor(WidgetTester tester) =>
      Theme.of(tester.element(chip())).colorScheme.error;

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(startButton());
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(InputDecorator, '할 일 연결 (선택)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, label));
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, '시작'));
    await tester.pumpAndSettle();
  }

  group('남은 시간 경계', () {
    for (final (allocated, label) in [(3600, '1:00:00'), (3599, '59:59')]) {
      testWidgets('남은 시간 $allocated초는 $label로 보인다', (tester) async {
        active = [
          activeTimer(
            status: TimerStatus.paused,
            allocatedDuration: allocated,
            elapsedTime: 0,
          ),
        ];
        await pumpTile(tester, [todo()]);

        expect(chipText(label), findsOneWidget);
        await unmount(tester);
      });
    }

    testWidgets('실행 중 1초 남으면 기본 색이고, 0이 되면 00:00을 에러 색으로 보이며 그 뒤로 줄지 않는다', (
      tester,
    ) async {
      active = [activeTimer(allocatedDuration: 131)];
      await pumpTile(tester, [todo()]);

      expect(chipText('00:01'), findsOneWidget);
      expect(renderedColor(tester, '00:01'), isNot(errorColor(tester)));

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(chipText('00:00'), findsOneWidget);
      expect(renderedColor(tester, '00:00'), errorColor(tester));

      now = now.add(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));

      expect(chipText('00:00'), findsOneWidget);
      expect(startButton(), findsNothing);
      await unmount(tester);
    });

    testWidgets('일시정지한 타이머의 남은 시간은 흐르지 않는다', (tester) async {
      active = [activeTimer(status: TimerStatus.paused, elapsedTime: 300)];
      await pumpTile(tester, [todo()]);
      expect(chipText('20:00'), findsOneWidget);

      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));

      expect(chipText('20:00'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('같은 할 일에 활성 타이머가 둘이어도 남은 시간은 하나만 보인다', (tester) async {
      active = [
        activeTimer(),
        activeTimer(id: 'timer-2', status: TimerStatus.paused),
      ];
      await pumpTile(tester, [todo()]);

      expect(chip(), findsOneWidget);
      expect(startButton(), findsNothing);
      await unmount(tester);
    });
  });

  group('하위 할 일과 상태 변화', () {
    testWidgets('하위 할 일의 활성 타이머는 하위 타일에만 남은 시간으로 보인다', (tester) async {
      active = [activeTimer(todoId: 'child')];
      await pumpTile(tester, [
        todo(),
        todo(id: 'child', title: '하위 일', parentId: 'todo-1'),
      ]);

      expect(chip(), findsOneWidget);
      expect(
        find.descendant(of: tileOf('child'), matching: chip()),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tileOf('child'), matching: startButton()),
        findsNothing,
      );
      expect(startButton(), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('활성 타이머가 끝나면 시작 버튼으로, 새로 시작되면 다시 남은 시간으로 바뀐다', (tester) async {
      active = [activeTimer()];
      await pumpTile(tester, [todo()]);
      expect(chip(), findsOneWidget);

      active = [];
      container(tester).invalidate(activeTimersProvider);
      await tester.pump();
      await tester.pump();

      expect(chip(), findsNothing);
      expect(startButton(), findsOneWidget);

      active = [activeTimer(id: 'timer-2', elapsedTime: 0)];
      container(tester).invalidate(activeTimersProvider);
      await tester.pump();
      await tester.pump();

      expect(startButton(), findsNothing);
      expect(chipText('24:30'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('타일에서 시작', () {
    testWidgets("다이얼로그에서 '연결 안 함'을 고르면 연결 없이 시작하고 할 일 화면에 머문다", (tester) async {
      final controller = _FakeTimerController();
      await pumpTile(tester, [todo()], controller: () => controller);

      await openDialog(tester);
      await choose(tester, '연결 안 함');
      await confirm(tester);

      expect(controller.starts, [
        (todoId: null, title: '보고서 쓰기', seconds: 25 * 60),
      ]);
      expect(location(), AppRoute.todo.path);
      await unmount(tester);
    });

    testWidgets('다이얼로그에서 다른 할 일과 시간을 고르면 그 할 일과 시간으로 시작한다', (tester) async {
      final controller = _FakeTimerController();
      await pumpTile(tester, [
        todo(),
        todo(id: 'todo-2', title: '회의 준비'),
      ], controller: () => controller);

      await openDialog(tester);
      await choose(tester, '회의 준비');
      await tester.tap(find.widgetWithText(ChoiceChip, '45분'));
      await tester.pump();
      await confirm(tester);

      expect(controller.starts, [
        (todoId: 'todo-2', title: '회의 준비', seconds: 45 * 60),
      ]);
      expect(location(), AppRoute.todo.path);
      await unmount(tester);
    });

    testWidgets('시작에 실패한 뒤 다시 시작하면 실패 알림을 시작 알림으로 바꾼다', (tester) async {
      final controller = _FakeTimerController()..error = Exception('서버 오류');
      await pumpTile(tester, [todo()], controller: () => controller);

      await openDialog(tester);
      await confirm(tester);
      expect(find.textContaining('타이머 시작 실패: '), findsOneWidget);
      expect(location(), AppRoute.todo.path);

      controller.error = null;
      await openDialog(tester);
      await confirm(tester);

      expect(controller.starts, hasLength(2));
      expect(location(), AppRoute.todo.path);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('타이머 시작 실패'), findsNothing);
      expect(find.text('타이머를 시작했습니다'), findsOneWidget);
      await unmount(tester);
    });

    for (final fails in [false, true]) {
      testWidgets(
        '시작 응답을 기다리는 사이 할 일 화면을 떠나도 ${fails ? '실패' : '성공'} 응답에 오류가 없다',
        (tester) async {
          final gate = Completer<void>();
          final controller = _FakeTimerController()
            ..gate = gate.future
            ..error = fails ? Exception('서버 오류') : null;
          await pumpTile(tester, [todo()], controller: () => controller);

          await openDialog(tester);
          await confirm(tester);
          router.go(AppRoute.calendar.path);
          await tester.pumpAndSettle();
          expect(find.byType(TodoTreeTile), findsNothing);

          gate.complete();
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(controller.starts, hasLength(1));
          await unmount(tester);
        },
      );
    }

    testWidgets('실제 컨트롤러로 응답을 기다렸다 시작해도 할 일을 연결해 만들고 할 일 화면에서 알린다', (
      tester,
    ) async {
      final repository = FakeTimerRepository();
      final gate = Completer<void>();
      repository.gate = gate.future;
      await pumpTile(
        tester,
        [todo()],
        overrides: [timerRepositoryProvider.overrideWithValue(repository)],
      );

      await openDialog(tester);
      await confirm(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(location(), AppRoute.todo.path);

      gate.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(repository.calls, ['create']);
      expect(repository.created?.todoId, 'todo-1');
      expect(repository.created?.title, '보고서 쓰기');
      expect(repository.created?.allocatedDuration, 25 * 60);
      expect(find.textContaining('타이머 시작 실패'), findsNothing);
      expect(find.text('타이머를 시작했습니다'), findsOneWidget);
      expect(location(), AppRoute.todo.path);
      await unmount(tester);
    });

    testWidgets('실제 컨트롤러가 실패하면 실패를 알리고 머문다', (tester) async {
      final repository = FakeTimerRepository()..error = Exception('서버 오류');
      await pumpTile(
        tester,
        [todo()],
        overrides: [timerRepositoryProvider.overrideWithValue(repository)],
      );

      await openDialog(tester);
      await confirm(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('타이머 시작 실패: '), findsOneWidget);
      expect(location(), AppRoute.todo.path);
      expect(startButton(), findsOneWidget);
      await unmount(tester);
    });
  });

  group('타일에서 연달아 시작', () {
    Finder startButtonOf(String id) =>
        find.descendant(of: tileOf(id), matching: startButton()).first;

    testWidgets('두 할 일을 연달아 시작해도 알림은 하나만 보이고 닫으면 쌓인 알림이 없다', (tester) async {
      final controller = _FakeTimerController();
      await pumpTile(
        tester,
        [todo(), todo(id: 'todo-2', title: '회의 준비', parentId: 'todo-1')],
        expanded: {'todo-1'},
        controller: () => controller,
      );

      await tester.tap(startButtonOf('todo-1'));
      await tester.pumpAndSettle();
      await confirm(tester);
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.tap(startButtonOf('todo-2'));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(controller.starts.map((start) => start.todoId), [
        'todo-1',
        'todo-2',
      ]);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(location(), AppRoute.todo.path);

      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      await unmount(tester);
    });

    testWidgets('시작 알림 뒤에 실패하면 실패 알림으로 바꾼다', (tester) async {
      final controller = _FakeTimerController();
      await pumpTile(tester, [todo()], controller: () => controller);

      await openDialog(tester);
      await confirm(tester);
      controller.error = Exception('서버 오류');
      // 시작 버튼이 남도록 활성 타이머 없이 다시 연다
      await openDialog(tester);
      await confirm(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('타이머 시작 실패'), findsOneWidget);
      expect(find.text('타이머를 시작했습니다'), findsNothing);
      await unmount(tester);
    });

    testWidgets('실제 컨트롤러로 시작하면 머문 채 타일에 남은 시간을 보여 준다', (tester) async {
      final repository = FakeTimerRepository()
        ..respond = (timerId, status) => makeTimer(
          id: timerId,
          status: status,
          startedAt: now,
          allocatedDuration: 1500,
        ).copyWith(todoId: 'todo-1');
      await pumpTile(
        tester,
        [todo()],
        liveActiveTimers: true,
        overrides: [
          timerRepositoryProvider.overrideWithValue(repository),
          timerWsClientProvider.overrideWithValue(null),
          currentUserProvider.overrideWithValue(null),
        ],
      );
      expect(startButton(), findsOneWidget);
      expect(chip(), findsNothing);

      await openDialog(tester);
      await confirm(tester);

      expect(location(), AppRoute.todo.path);
      expect(startButton(), findsNothing);
      expect(chipText('25:00'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('타일에서 여러 할 일로 시작', () {
    final todos = [
      todo(),
      todo(id: 'todo-2', title: '회의 준비'),
      todo(id: 'todo-3', title: '코드 리뷰'),
    ];

    Finder checkbox(String label) => find.descendant(
      of: find.widgetWithText(ListTile, label),
      matching: find.byType(Checkbox),
    );

    /// 타일의 할 일을 체크한 채 연 목록에서 [labels]를 더 체크하고 시작한다
    Future<void> startWithMore(WidgetTester tester, List<String> labels) async {
      await openDialog(tester);
      await tester.tap(find.widgetWithText(InputDecorator, '할 일 연결 (선택)'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(checkbox('보고서 쓰기')).value, isTrue);
      for (final label in labels) {
        await tester.tap(checkbox(label));
        await tester.pump();
      }
      await tester.tap(
        find.widgetWithText(FilledButton, '${labels.length + 1}개 선택 완료'),
      );
      await tester.pumpAndSettle();
      await confirm(tester);
    }

    testWidgets('타일의 할 일에 다른 할 일을 더 고르면 할 일마다 시작하고 머물며 알린다', (tester) async {
      final controller = _FakeTimerController();
      await pumpTile(tester, todos, controller: () => controller);

      await startWithMore(tester, ['코드 리뷰']);

      expect(controller.starts, isEmpty);
      expect(controller.multiStarts.single.todoIds, ['todo-1', 'todo-3']);
      expect(
        controller.multiStarts.single.duration,
        const Duration(minutes: 25),
      );
      expect(location(), AppRoute.todo.path);
      expect(find.text('타이머를 시작했습니다'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, '타이머 보기'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('일부가 실패하면 시작하지 못한 할 일만 알리고 머문다', (tester) async {
      final controller = _FakeTimerController()..failedTodoIds = {'todo-2'};
      await pumpTile(tester, todos, controller: () => controller);

      await startWithMore(tester, ['회의 준비', '코드 리뷰']);

      expect(controller.multiStarts.single.todoIds, [
        'todo-1',
        'todo-2',
        'todo-3',
      ]);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('타이머 시작 실패: 회의 준비'), findsOneWidget);
      expect(location(), AppRoute.todo.path);
      await unmount(tester);
    });
  });

  group('화면 크기', () {
    final tag = TagRead(
      id: 'tag-1',
      name: '아주 긴 태그 이름이 들어가도 넘치지 않아야 한다',
      color: '#FF0000',
      groupId: 'group-1',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    const longTitle = '아주 긴 할 일 제목이 들어가도 할 일 타일이 넘치지 않아야 한다';

    /// 루트 > 중간 > 끝 > 끝의 하위. 끝(두 단계 아래)에 남은 시간, 끝의 하위(세 단계 아래)에 시작 버튼이 있다
    List<TodoRead> deepTree() => [
      todo(title: longTitle).copyWith(
        tags: [
          tag,
          tag.copyWith(id: 'tag-2'),
        ],
      ),
      todo(id: 'mid', title: longTitle, parentId: 'todo-1'),
      todo(id: 'leaf', title: longTitle, parentId: 'mid').copyWith(
        tags: [
          tag,
          tag.copyWith(id: 'tag-2'),
        ],
      ),
      todo(id: 'leaf-child', parentId: 'leaf'),
    ];

    for (final size in const [
      Size(360, 800),
      Size(360, 560),
      Size(844, 390),
      Size(800, 1280),
      Size(1280, 800),
    ]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$label 화면에서 세 단계 아래까지 h:mm:ss 남은 시간과 시작 버튼이 넘치지 않는다', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        active = [activeTimer(todoId: 'leaf', allocatedDuration: 40000)];

        await pumpTile(tester, deepTree(), expanded: {'mid', 'leaf'});

        expect(tester.takeException(), isNull);
        expect(chipText('11:04:30'), findsOneWidget);
        expect(
          find.descendant(of: tileOf('leaf'), matching: chip()),
          findsOneWidget,
        );
        expect(startButton(), findsNWidgets(3));
        await unmount(tester);
      });

      testWidgets('$label 화면에서 타일로 연 다이얼로그와 할 일 목록이 넘치지 않는다', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final controller = _FakeTimerController();

        await pumpTile(tester, [
          todo(title: longTitle),
        ], controller: () => controller);
        await openDialog(tester);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(
          find.widgetWithText(InputDecorator, '할 일 연결 (선택)'),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(InputDecorator, '할 일 연결 (선택)'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.widgetWithText(FilledButton, '시작'));
        await tester.pumpAndSettle();
        await confirm(tester);

        expect(tester.takeException(), isNull);
        expect(controller.starts, [
          (todoId: 'todo-1', title: longTitle, seconds: 25 * 60),
        ]);
        await unmount(tester);
      });
    }
  });
}

/// startTimer 호출을 기록하는 컨트롤러
class _FakeTimerController extends TimerController {
  final starts = <({String? todoId, String? title, int? seconds})>[];

  /// 설정하면 startTimer가 이 예외를 던진다
  Object? error;

  /// 설정하면 startTimer가 이 Future가 끝날 때까지 응답하지 않는다
  Future<void>? gate;

  /// startTimers로 받은 할 일 id와 집중 시간
  final multiStarts = <({List<String> todoIds, Duration duration})>[];

  /// startTimers가 시작하지 못한 것으로 돌려줄 할 일 id
  Set<String> failedTodoIds = {};

  @override
  FutureOr<void> build() {}

  @override
  Future<List<TodoRead>> startTimers({
    required List<TodoRead> todos,
    required Duration duration,
  }) async {
    multiStarts.add((
      todoIds: [for (final todo in todos) todo.id],
      duration: duration,
    ));
    return [
      for (final todo in todos)
        if (failedTodoIds.contains(todo.id)) todo,
    ];
  }

  @override
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    starts.add((
      todoId: relatedTodoId,
      title: title,
      seconds: allocatedDurationSeconds,
    ));
    await gate;
    if (error != null) throw error!;
  }
}
