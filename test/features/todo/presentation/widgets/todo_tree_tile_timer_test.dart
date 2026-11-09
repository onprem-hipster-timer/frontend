import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree_tile.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/timer_fixtures.dart';

void main() {
  late DateTime now;
  late _FakeTimerController controller;
  late GoRouter router;

  setUp(() {
    now = DateTime.utc(2026, 11, 6, 10, 0, 30);
    controller = _FakeTimerController();
  });

  TodoRead todo({
    String id = 'todo-1',
    String title = '보고서 쓰기',
    TodoStatus status = TodoStatus.unscheduled,
    bool shared = false,
  }) =>
      makeTodo(id: id).copyWith(title: title, status: status, isShared: shared);

  /// todo-1에 연결된 활성 타이머. 10:00에 시작했거나 그때까지 [elapsedTime]초를 센 타이머
  TimerRead activeTimer({
    TimerStatus status = TimerStatus.running,
    int allocatedDuration = 1500,
    int elapsedTime = 100,
  }) => makeTimer(
    id: 'timer-1',
    status: status,
    startedAt: DateTime.utc(2026, 11, 6, 10),
    allocatedDuration: allocatedDuration,
    elapsedTime: elapsedTime,
  ).copyWith(todoId: 'todo-1');

  /// 할 일 화면에 [root]와 하위 [children]의 타일을 그린다. 타이머 화면은 '타이머 화면' 글자만 둔다
  Future<void> pumpTile(
    WidgetTester tester,
    TodoRead root, {
    List<TodoRead> children = const [],
    List<TimerRead> active = const [],
    int finishedSeconds = 0,
  }) async {
    final tree = buildTodoTree([root, ...children]);
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
                  child: TodoTreeTile(node: tree.nodeMap[root.id]!, tree: tree),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.timer.path,
          builder: (context, state) => const Scaffold(body: Text('타이머 화면')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          timerControllerProvider.overrideWith(() => controller),
          activeTimersProvider.overrideWith((ref) async => active),
          todoTimerAggregationsProvider.overrideWith(
            (ref) async => {
              root.id: TodoTimerAggregation(
                todoId: root.id,
                totalElapsedSeconds: finishedSeconds,
                ownElapsedSeconds: finishedSeconds,
                timers: const [],
                hasActiveTimer: false,
              ),
            },
          ),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => now),
          ),
          allTodosProvider.overrideWith((ref) async => [root, ...children]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// 1초마다 내는 활성 타이머 스트림을 멈춘다
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  Finder startButton() => find.byTooltip('타이머 시작');
  Finder chip() => find.byType(ActionChip);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(startButton());
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, '시작'));
    await tester.pumpAndSettle();
  }

  group('타이머 시작 버튼', () {
    testWidgets('내 할 일에는 타이머 시작 버튼이 있고 남은 시간은 없다', (tester) async {
      await pumpTile(tester, todo());

      expect(startButton(), findsOneWidget);
      expect(
        find.widgetWithIcon(IconButton, Icons.play_circle_outline),
        findsOneWidget,
      );
      expect(chip(), findsNothing);
      await unmount(tester);
    });

    for (final (label, hidden) in [
      ('완료한', todo(status: TodoStatus.done)),
      ('취소한', todo(status: TodoStatus.cancelled)),
      ('공유받은', todo(shared: true)),
    ]) {
      testWidgets('$label 할 일에는 연결된 활성 타이머가 있어도 시작 버튼과 남은 시간이 없다', (
        tester,
      ) async {
        await pumpTile(tester, hidden, active: [activeTimer()]);

        expect(startButton(), findsNothing);
        expect(chip(), findsNothing);
        await unmount(tester);
      });
    }

    testWidgets('누르면 이 할 일을 고른 새 작업 시작 다이얼로그를 기본 집중 시간으로 연다', (tester) async {
      await pumpTile(tester, todo());

      await openDialog(tester);

      expect(find.text('새 작업 시작'), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(InputDecorator, '할 일 연결 (선택)'),
          matching: find.text('보고서 쓰기'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, '작업명'))
            .controller
            ?.text,
        '보고서 쓰기',
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '25분'))
            .selected,
        isTrue,
      );
      await unmount(tester);
    });

    testWidgets('시작하면 이 할 일을 연결해 시작하고 할 일 화면에 머물며 알린다', (tester) async {
      await pumpTile(tester, todo());

      await openDialog(tester);
      await confirm(tester);

      expect(controller.starts, [
        (todoId: 'todo-1', title: '보고서 쓰기', seconds: 25 * 60),
      ]);
      expect(location(), AppRoute.todo.path);
      expect(find.text('타이머 화면'), findsNothing);
      expect(find.widgetWithText(SnackBar, '타이머를 시작했습니다'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, '타이머 보기'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets("알림의 '타이머 보기'를 누르면 타이머 화면으로 간다", (tester) async {
      await pumpTile(tester, todo());

      await openDialog(tester);
      await confirm(tester);
      await tester.tap(find.widgetWithText(SnackBarAction, '타이머 보기'));
      await tester.pumpAndSettle();

      expect(location(), AppRoute.timer.path);
      expect(find.text('타이머 화면'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('시작에 실패하면 알리고 할 일 화면에 머문다', (tester) async {
      controller.error = Exception('서버 오류');
      await pumpTile(tester, todo());

      await openDialog(tester);
      await confirm(tester);

      expect(controller.starts, hasLength(1));
      expect(find.textContaining('타이머 시작 실패'), findsOneWidget);
      expect(location(), AppRoute.todo.path);
      expect(startButton(), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('다이얼로그를 취소하면 시작하지 않고 머문다', (tester) async {
      await pumpTile(tester, todo());

      await openDialog(tester);
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(controller.starts, isEmpty);
      expect(location(), AppRoute.todo.path);
      await unmount(tester);
    });

    testWidgets('새 타이머를 시작하는 동안에는 누를 수 없다', (tester) async {
      final gate = Completer<void>();
      controller.gate = gate.future;
      await pumpTile(tester, todo());

      await openDialog(tester);
      await tester.tap(find.widgetWithText(FilledButton, '시작'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.play_circle_outline),
            )
            .onPressed,
        isNull,
      );
      expect(location(), AppRoute.todo.path);

      gate.complete();
      await tester.pumpAndSettle();

      expect(location(), AppRoute.todo.path);
      expect(find.text('타이머를 시작했습니다'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('남은 시간', () {
    testWidgets('진행 중인 타이머가 있으면 시작 버튼 대신 남은 시간을 1초마다 보여 준다', (tester) async {
      await pumpTile(tester, todo(), active: [activeTimer()]);

      expect(startButton(), findsNothing);
      expect(
        find.descendant(of: chip(), matching: find.text('22:50')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: chip(),
          matching: find.byIcon(Icons.timer_outlined),
        ),
        findsOneWidget,
      );

      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.descendant(of: chip(), matching: find.text('22:49')),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('일시정지한 타이머도 남은 시간을 보여 준다', (tester) async {
      await pumpTile(
        tester,
        todo(),
        active: [activeTimer(status: TimerStatus.paused, elapsedTime: 300)],
      );

      expect(startButton(), findsNothing);
      expect(
        find.descendant(of: chip(), matching: find.text('20:00')),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('한 시간 이상 남으면 h:mm:ss로 보여 준다', (tester) async {
      await pumpTile(
        tester,
        todo(),
        active: [activeTimer(allocatedDuration: 4000)],
      );

      expect(
        find.descendant(of: chip(), matching: find.text('1:04:30')),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('남은 시간이 0이면 00:00을 에러 색으로 보여 준다', (tester) async {
      await pumpTile(
        tester,
        todo(),
        active: [
          activeTimer(
            status: TimerStatus.paused,
            allocatedDuration: 1500,
            elapsedTime: 1500,
          ),
        ],
      );

      expect(
        find.descendant(of: chip(), matching: find.text('00:00')),
        findsOneWidget,
      );
      // 글자와 아이콘이 실제로 그려지는 색
      Color? rendered(Finder finder) => tester
          .widget<RichText>(
            find.descendant(
              of: find.descendant(of: chip(), matching: finder),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style
          ?.color;
      final error = Theme.of(tester.element(chip())).colorScheme.error;
      expect(rendered(find.text('00:00')), error);
      expect(rendered(find.byIcon(Icons.timer_outlined)), error);
      await unmount(tester);
    });

    testWidgets('남은 시간을 누르면 타이머 화면으로 간다', (tester) async {
      await pumpTile(tester, todo(), active: [activeTimer()]);

      expect(find.byTooltip('타이머로 이동'), findsOneWidget);
      await tester.tap(chip());
      await tester.pumpAndSettle();

      expect(location(), AppRoute.timer.path);
      expect(controller.starts, isEmpty);
      await unmount(tester);
    });
  });

  group('360 폭', () {
    final tag = TagRead(
      id: 'tag-1',
      name: '업무',
      color: '#FF0000',
      groupId: 'group-1',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final long = todo(title: '아주 긴 할 일 제목이 들어가도 할 일 타일이 넘치지 않아야 한다').copyWith(
      tags: [
        tag.copyWith(name: '아주 긴 태그 이름이 들어가도 넘치지 않아야 한다'),
        tag.copyWith(id: 'tag-2'),
      ],
    );
    final child = makeTodo(id: 'child').copyWith(parentId: 'todo-1');

    for (final (label, active, control) in [
      ('시작 버튼', <TimerRead>[], startButton),
      ('남은 시간', [activeTimer()], chip),
    ]) {
      testWidgets('긴 제목·태그·하위 개수·누적 시간과 $label이 넘치지 않는다', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpTile(
          tester,
          long,
          children: [child],
          active: active,
          finishedSeconds: 1500,
        );

        expect(tester.takeException(), isNull);
        expect(control(), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);
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

  @override
  FutureOr<void> build() {}

  @override
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    state = const AsyncValue.loading();
    starts.add((
      todoId: relatedTodoId,
      title: title,
      seconds: allocatedDurationSeconds,
    ));
    await gate;
    if (error != null) {
      state = AsyncValue.error(error!, StackTrace.current);
      throw error!;
    }
    state = const AsyncValue.data(null);
  }
}
