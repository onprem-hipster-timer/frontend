import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

const _confirmTitle = '작업 완료';
const _confirmContent =
    '작업을 완료하시겠습니까?\n완료한 타이머는 다시 시작할 수 없습니다.\n잠시 멈추려면 일시정지를 이용해 주세요.';

void main() {
  TimerWsTimerEvent activity({
    String action = 'start',
    String? displayName,
    String? timerTitle,
  }) {
    return TimerWsTimerEvent(
      id: 'msg-1',
      type: 'timer.updated',
      fromUser: 'friend-1',
      timestamp: DateTime.utc(2026, 11, 6),
      payload: TimerWsEventPayload(
        action: action,
        actorName: displayName,
        timer: makeTimer(
          id: 'timer-1',
          status: TimerStatus.running,
        ).copyWith(title: timerTitle),
      ),
    );
  }

  // ============================================================
  // friendActivityMessage — 문구 매핑 (순수 함수)
  // ============================================================
  group('friendActivityMessage', () {
    group('actor_name 처리', () {
      test('actor_name이 있으면 이름이 문구에 반영된다', () {
        final msg = friendActivityMessage(activity(displayName: '홍길동'));
        expect(msg, contains('홍길동님이'));
      });

      test('actor_name이 null이면 "친구" fallback을 쓴다', () {
        final msg = friendActivityMessage(activity());
        expect(msg, startsWith('친구님이'));
      });

      test('actor_name이 빈 문자열이면 "친구" fallback을 쓴다', () {
        final msg = friendActivityMessage(activity(displayName: '   '));
        expect(msg, startsWith('친구님이'));
      });
    });

    group('action별 문구', () {
      test('start', () {
        expect(
          friendActivityMessage(activity(action: 'start', displayName: '철수')),
          '철수님이 타이머를 시작했습니다',
        );
      });

      test('pause', () {
        expect(
          friendActivityMessage(activity(action: 'pause', displayName: '철수')),
          '철수님이 타이머를 일시정지했습니다',
        );
      });

      test('resume', () {
        expect(
          friendActivityMessage(activity(action: 'resume', displayName: '철수')),
          '철수님이 타이머를 재개했습니다',
        );
      });

      test('stop', () {
        expect(
          friendActivityMessage(activity(action: 'stop', displayName: '철수')),
          '철수님이 타이머를 정지했습니다',
        );
      });
    });

    group('그 외 action — generic fallback', () {
      test('update는 generic fallback으로 처리된다', () {
        expect(
          friendActivityMessage(activity(action: 'update', displayName: '철수')),
          '철수님의 타이머 상태가 변경되었습니다',
        );
      });

      test('delete는 generic fallback으로 처리된다', () {
        expect(
          friendActivityMessage(activity(action: 'delete', displayName: '철수')),
          '철수님의 타이머 상태가 변경되었습니다',
        );
      });

      test('알 수 없는 action은 generic fallback으로 처리된다', () {
        expect(
          friendActivityMessage(
            activity(action: 'whatever', displayName: '철수'),
          ),
          '철수님의 타이머 상태가 변경되었습니다',
        );
      });
    });

    test('timerTitle이 있으면 "<제목> 타이머"로 표시된다', () {
      final msg = friendActivityMessage(
        activity(displayName: '철수', timerTitle: '집중'),
      );
      expect(msg, '철수님이 집중 타이머를 시작했습니다');
    });
  });

  // ============================================================
  // TimerPage — 친구 활동 수신 시 SnackBar 표시 (provider 동작)
  // ============================================================
  group('친구 활동 SnackBar', () {
    late StreamController<TimerWsTimerEvent> controller;

    setUp(() => controller = StreamController<TimerWsTimerEvent>());
    tearDown(() => controller.close());

    Widget buildPage() {
      return pumpApp(
        const TimerPage(),
        overrides: [
          // UI-scoped 알림 스트림을 제어 가능한 컨트롤러로 대체
          timerFriendActivityProvider.overrideWith((ref) => controller.stream),
          // 실제 REST/WS·주기 타이머 호출을 막기 위한 대체
          activeTimerProvider.overrideWithValue(const AsyncData(null)),
          timerHistoryProvider.overrideWith(
            (ref) => Future.value(<TimerRead>[]),
          ),
          timerTickerProvider.overrideWith(
            (ref) => Stream.value(Duration.zero),
          ),
        ],
      );
    }

    testWidgets('친구 활동 이벤트 수신 시 SnackBar가 문구와 함께 표시된다', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();

      controller.add(activity(action: 'start', displayName: '영희'));
      await tester.pump(); // 스트림 이벤트 전달
      await tester.pump(); // SnackBar 등장 프레임

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('영희님이 타이머를 시작했습니다'), findsOneWidget);
    });

    testWidgets('actor_name이 없으면 SnackBar에 "친구" fallback이 표시된다', (
      tester,
    ) async {
      await tester.pumpWidget(buildPage());
      await tester.pump();

      controller.add(activity(action: 'pause'));
      await tester.pump();
      await tester.pump();

      expect(find.text('친구님이 타이머를 일시정지했습니다'), findsOneWidget);
    });
  });

  // ============================================================
  // TimerPage — 완료 확인 모달 (대시보드 + 히스토리)
  // ============================================================
  group('TimerPage 완료 확인', () {
    testWidgets('완료 버튼을 탭하면 확인 다이얼로그를 표시한다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_dashboardFabByIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsOneWidget);
      expect(find.text(_confirmContent), findsOneWidget);
      expect(find.widgetWithText(TextButton, '취소'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '완료'), findsOneWidget);
    });

    testWidgets('취소를 탭하면 다이얼로그를 닫고 정지하지 않는다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_dashboardFabByIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsNothing);
      expect(controller.stopCalled, isFalse);
    });

    testWidgets('완료를 탭하면 정지하고 새 타이머 시작 액션을 표시한다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_dashboardFabByIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '완료'));
      await tester.pumpAndSettle();

      expect(controller.stopCalled, isTrue);
      // 확인 시점에 캡처한 활성 타이머 id로 정지해야 한다 (async race 방지).
      expect(controller.stoppedTimerId, 'timer-1');
      expect(find.text('작업을 완료했습니다'), findsOneWidget);
      expect(find.text('새 타이머 시작'), findsOneWidget);
    });

    testWidgets('RUNNING 상태에서 일시정지는 큰 FAB이고 완료는 작은 FAB이다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      final completeSize = tester.getSize(_dashboardFabByIcon(Icons.check));
      final pauseSize = tester.getSize(_dashboardFabByIcon(Icons.pause));

      expect(pauseSize.width, greaterThan(completeSize.width));
      expect(pauseSize.height, greaterThan(completeSize.height));
    });

    testWidgets('대시보드와 타이머 목록의 완료 버튼은 툴팁이 완료다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      expect(find.byTooltip('완료'), findsNWidgets(2));
      expect(find.byTooltip('정지'), findsNothing);
    });

    testWidgets('일시정지는 확인 없이 바로 보낸다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(
        tester,
        timer: makeTimer(id: 'timer-1', status: TimerStatus.running),
        controller: controller,
      );
      await tester.tap(_dashboardFabByIcon(Icons.pause));
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
      expect(controller.paused, isTrue);
    });

    testWidgets('재개는 확인 없이 바로 보낸다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(
        tester,
        timer: makeTimer(id: 'timer-1', status: TimerStatus.paused),
        controller: controller,
      );
      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
      expect(controller.resumed, isTrue);
    });

    testWidgets('히스토리 목록 완료 버튼도 확인 다이얼로그를 거친다', (tester) async {
      final timer = makeTimer(id: 'timer-1', status: TimerStatus.running);
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: timer, controller: controller);

      await tester.tap(_historyCompleteButton());
      await tester.pumpAndSettle();

      expect(find.text(_confirmTitle), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(controller.stopCalled, isFalse);
    });
  });

  // ============================================================
  // TimerPage — 남은 시간 (대시보드 + 타이머 목록)
  // ============================================================
  group('남은 시간 표시', () {
    testWidgets('대시보드는 할당 시간에서 경과 시간을 뺀 남은 시간을 보여 준다', (tester) async {
      final timer = makeTimer(
        id: 'timer-1',
        status: TimerStatus.paused,
        allocatedDuration: 25 * 60,
        elapsedTime: 5 * 60,
      );

      await _pumpTimerPage(
        tester,
        timer: timer,
        controller: _FakeTimerController(),
      );

      expect(_clockText(tester), '00:20:00');
      expect(find.text('시간 종료'), findsNothing);
    });

    testWidgets('남은 시간이 0이면 00:00:00과 시간 종료를 보여 주고 모달은 띄우지 않는다', (
      tester,
    ) async {
      final timer = makeTimer(
        id: 'timer-1',
        status: TimerStatus.running,
        allocatedDuration: 60,
        elapsedTime: 90,
      );

      await _pumpTimerPage(
        tester,
        timer: timer,
        controller: _FakeTimerController(),
      );

      expect(_clockText(tester), '00:00:00');
      expect(find.text('시간 종료'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      final clock = tester.widget<Text>(
        find.descendant(
          of: find.byType(DigitalClock),
          matching: find.byType(Text),
        ),
      );
      final colors = Theme.of(tester.element(find.byType(DigitalClock)));
      expect(clock.style?.color, colors.colorScheme.error);
    });

    testWidgets('타이머 목록의 진행 중 항목은 남은 시간, 완료 항목은 경과 시간이다', (tester) async {
      final active = makeTimer(
        id: 'timer-1',
        status: TimerStatus.paused,
        allocatedDuration: 25 * 60,
        elapsedTime: 5 * 60,
      );
      final completed = makeTimer(
        id: 'timer-2',
        status: TimerStatus.completed,
        allocatedDuration: 25 * 60,
        elapsedTime: 10 * 60,
      );

      await _pumpTimerPage(
        tester,
        timer: active,
        history: [active, completed],
        controller: _FakeTimerController(),
      );

      expect(
        find.descendant(
          of: _historyItem('timer-1'),
          matching: find.text('00:20:00'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _historyItem('timer-2'),
          matching: find.text('00:10:00'),
        ),
        findsOneWidget,
      );
    });
  });

  // ============================================================
  // TimerPage — 연결된 Todo의 상태 (일시정지 후 바로 바꾸기)
  // ============================================================
  group('연결된 Todo 상태', () {
    late _MockTodosClient todosApi;

    setUpAll(() => registerFallbackValue(TodoUpdate()));

    setUp(() {
      todosApi = _MockTodosClient();
      when(
        () => todosApi.updateTodoV1TodosTodoIdPatch(
          todoId: any(named: 'todoId'),
          body: any(named: 'body'),
          timezone: any(named: 'timezone'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => makeTodo().copyWith(status: TodoStatus.done));
    });

    TimerRead withTodo(TimerStatus status) => makeTimer(
      id: 'timer-1',
      status: status,
    ).copyWith(todoId: 'todo-1', todo: makeTodo());

    Future<_FakeTimerController> pump(
      WidgetTester tester,
      TimerRead timer,
    ) async {
      final controller = _FakeTimerController();
      await _pumpTimerPage(
        tester,
        timer: timer,
        controller: controller,
        overrides: [todosApiProvider.overrideWithValue(todosApi)],
      );
      return controller;
    }

    testWidgets('일시정지면 Todo 상태 선택기를 보여 주고 완료를 고르면 Todo만 바꾼다', (tester) async {
      final controller = await pump(tester, withTodo(TimerStatus.paused));

      await tester.tap(find.byType(TodoStatusSelector));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PopupMenuItem<TodoStatus>),
          matching: find.text(TodoStatus.done.label),
        ),
      );
      await tester.pumpAndSettle();

      final body =
          verify(
                () => todosApi.updateTodoV1TodosTodoIdPatch(
                  todoId: 'todo-1',
                  body: captureAny(named: 'body'),
                  timezone: any(named: 'timezone'),
                  options: any(named: 'options'),
                ),
              ).captured.single
              as TodoUpdate;
      expect(body.status, TodoStatus.done);
      expect(controller.stopCalled, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('실행 중이면 Todo 상태 아이콘만 보여 준다', (tester) async {
      await pump(tester, withTodo(TimerStatus.running));

      expect(find.byType(TodoStatusSelector), findsNothing);
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(CurrentTaskDisplay),
          matching: find.byIcon(TodoStatus.unscheduled.icon),
        ),
      );
      expect(
        icon.color,
        TodoStatus.unscheduled.color(tester.element(find.byType(TimerPage))),
      );
    });

    testWidgets('연결된 Todo가 없으면 상태를 보여 주지 않는다', (tester) async {
      await pump(tester, makeTimer(id: 'timer-1', status: TimerStatus.paused));

      expect(find.byType(TodoStatusSelector), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CurrentTaskDisplay),
          matching: find.byIcon(TodoStatus.unscheduled.icon),
        ),
        findsNothing,
      );
    });
  });

  // ============================================================
  // TimerPage — 새 작업 시작 다이얼로그의 집중 시간
  // ============================================================
  group('새 작업 시작 집중 시간', () {
    testWidgets('기본은 25분이고 그대로 시작하면 25분으로 시작한다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: null, controller: controller);
      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '25분'),
      );
      expect(chip.selected, isTrue);

      await tester.tap(find.widgetWithText(FilledButton, '시작'));
      await tester.pumpAndSettle();

      expect(controller.startedAllocatedDurationSeconds, 25 * 60);
    });

    testWidgets('고른 집중 시간으로 시작한다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: null, controller: controller);
      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      for (final minutes in [15, 25, 45, 60]) {
        expect(find.widgetWithText(ChoiceChip, '$minutes분'), findsOneWidget);
      }

      await tester.tap(find.widgetWithText(ChoiceChip, '45분'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '시작'));
      await tester.pumpAndSettle();

      expect(controller.startedAllocatedDurationSeconds, 45 * 60);
    });

    testWidgets('분을 입력하면 그 시간으로 시작하고 고른 칩은 풀린다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: null, controller: controller);
      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '50');
      await tester.pump();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips.where((chip) => chip.selected), isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, '시작'));
      await tester.pumpAndSettle();

      expect(controller.startedAllocatedDurationSeconds, 50 * 60);
    });

    testWidgets('칩을 고르면 분 칸을 채우고, 그 뒤에 입력한 분으로 시작한다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: null, controller: controller);
      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '45분'));
      await tester.pump();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller
            ?.text,
        '45',
      );

      await tester.enterText(find.byType(TextFormField), '50');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '시작'));
      await tester.pumpAndSettle();

      expect(controller.startedAllocatedDurationSeconds, 50 * 60);
    });

    testWidgets('분이 비었거나 1~600 밖이면 시작할 수 없다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: null, controller: controller);
      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      for (final text in ['', '0', '601']) {
        await tester.enterText(find.byType(TextFormField), text);
        await tester.pump();

        final start = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, '시작'),
        );
        expect(start.onPressed, isNull, reason: text);
        expect(find.text('1~600분'), findsOneWidget, reason: text);
      }

      await tester.tap(find.widgetWithText(FilledButton, '시작'));
      await tester.pumpAndSettle();

      expect(controller.startedAllocatedDurationSeconds, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}

Future<void> _pumpTimerPage(
  WidgetTester tester, {
  required TimerRead? timer,
  List<TimerRead>? history,
  required _FakeTimerController controller,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    pumpApp(
      const TimerPage(),
      overrides: [
        ..._timerOverrides(
          timer: timer,
          history: history ?? [?timer],
          controller: controller,
        ),
        ...overrides,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

List<Override> _timerOverrides({
  required TimerRead? timer,
  required List<TimerRead> history,
  required _FakeTimerController controller,
}) {
  return [
    // 친구 활동 리스너가 실제 WS/auth 체인을 건드리지 않도록 빈 스트림으로 격리
    timerFriendActivityProvider.overrideWith(
      (ref) => const Stream<TimerWsTimerEvent>.empty(),
    ),
    activeTimerProvider.overrideWithValue(AsyncData(timer)),
    timerHistoryProvider.overrideWith((ref) => Future.value(history)),
    timerTickerProvider.overrideWith(
      (ref) => Stream.value(
        timer == null
            ? Duration.zero
            : displayRemaining(timer, DateTime.utc(2026, 11, 6)),
      ),
    ),
    timerControllerProvider.overrideWith(() => controller),
  ];
}

Finder _dashboardFabByIcon(IconData icon) {
  final iconInFab = find.descendant(
    of: find.byType(FloatingActionButton),
    matching: find.byIcon(icon),
  );
  return find.ancestor(
    of: iconInFab,
    matching: find.byType(FloatingActionButton),
  );
}

String? _clockText(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byType(DigitalClock),
        matching: find.byType(Text),
      ),
    )
    .data;

Finder _historyItem(String timerId) => find.byWidgetPredicate(
  (widget) => widget is TimerHistoryItem && widget.timer.id == timerId,
);

Finder _historyCompleteButton() {
  final iconInButton = find.descendant(
    of: find.byType(IconButton),
    matching: find.byIcon(Icons.check),
  );
  return find.ancestor(of: iconInButton, matching: find.byType(IconButton));
}

class _MockTodosClient extends Mock implements TodosClient {}

class _FakeTimerController extends TimerController {
  bool stopCalled = false;
  String? stoppedTimerId;
  int? startedAllocatedDurationSeconds;
  bool paused = false;
  bool resumed = false;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> stopTimer({String? timerId}) async {
    stopCalled = true;
    stoppedTimerId = timerId;
  }

  @override
  Future<void> pauseTimer({String? timerId}) async => paused = true;

  @override
  Future<void> resumeTimer({String? timerId}) async => resumed = true;

  @override
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    startedAllocatedDurationSeconds = allocatedDurationSeconds;
  }
}
