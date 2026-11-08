import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/providers/api_providers.dart';

import '../../../../helpers/fake_timer_repository.dart';
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

      test('expire', () {
        expect(
          friendActivityMessage(
            activity(action: 'expire', displayName: '철수', timerTitle: '집중'),
          ),
          '철수님의 집중 타이머가 끝났습니다',
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
  group('명령 중 표시', () {
    Future<void> pumpLoading(
      WidgetTester tester, {
      required TimerRead? timer,
      List<TimerRead>? history,
      Map<String, TimerRead> views = const {},
    }) async {
      await tester.pumpWidget(
        pumpApp(
          const TimerPage(),
          overrides: [
            ..._timerOverrides(
              timer: timer,
              history: history ?? [?timer],
              controller: _LoadingTimerController(),
            ),
            timerViewsProvider.overrideWith(() => _FixedViews(views)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('새 타이머를 시작하는 동안 시작 버튼 안에 진행 표시를 두고 다시 열지 않는다', (tester) async {
      await pumpLoading(tester, timer: null);

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      expect(
        find.descendant(
          of: fab,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<FloatingActionButton>(fab).onPressed, isNull);
    });

    testWidgets('활성 타이머가 있으면 컨트롤러 상태와 무관하게 버튼을 그대로 둔다', (tester) async {
      await pumpLoading(
        tester,
        timer: makeTimer(id: 'timer-1', status: TimerStatus.running),
      );

      expect(_dashboardFabByIcon(Icons.pause), findsOneWidget);
      expect(_dashboardFabByIcon(Icons.check), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byTooltip('일시정지'), findsOneWidget);
    });

    testWidgets('타이머 목록은 명령 응답 전 값을 목록보다 먼저 보인다', (tester) async {
      final listed = makeTimer(id: 'timer-1', status: TimerStatus.running);
      await pumpLoading(
        tester,
        timer: null,
        history: [listed],
        views: {'timer-1': listed.copyWith(status: TimerStatus.paused)},
      );

      expect(
        find.descendant(
          of: _historyItem('timer-1'),
          matching: find.text('일시정지'),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('재개'), findsOneWidget);
      expect(find.byTooltip('일시정지'), findsNothing);
    });

    testWidgets('목록 값이 더 나중이면 목록 값을 보인다', (tester) async {
      final listed = makeTimer(
        id: 'timer-1',
        status: TimerStatus.running,
      ).copyWith(updatedAt: DateTime.utc(2026, 1, 1, 0, 5));
      await pumpLoading(
        tester,
        timer: null,
        history: [listed],
        views: {
          'timer-1': listed.copyWith(
            status: TimerStatus.paused,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        },
      );

      expect(find.byTooltip('일시정지'), findsOneWidget);
      expect(find.byTooltip('재개'), findsNothing);
    });
  });

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

  group('시간 종료', () {
    final expired = makeTimer(
      id: 'timer-1',
      status: TimerStatus.paused,
      allocatedDuration: 25 * 60,
      elapsedTime: 25 * 60,
    );

    void expectExtendOnly() {
      expect(find.text('시간 종료'), findsOneWidget);
      final extend = _dashboardFabByIcon(Icons.add);
      expect(extend, findsOneWidget);
      expect(
        find.descendant(of: extend, matching: find.byTooltip('5분 연장')),
        findsOneWidget,
      );
      expect(_dashboardFabByIcon(Icons.check), findsOneWidget);
      expect(_dashboardFabByIcon(Icons.pause), findsNothing);
      expect(_dashboardFabByIcon(Icons.play_arrow), findsNothing);
    }

    testWidgets('시간이 끝나 일시정지된 타이머는 완료와 5분 연장만 보여 주고 연장을 누르면 5분 늘린다', (
      tester,
    ) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: expired, controller: controller);

      expectExtendOnly();

      await tester.tap(_dashboardFabByIcon(Icons.add));
      await tester.pump();

      expect(controller.extendedBy, const Duration(minutes: 5));
      expect(controller.extendedTimerId, isNull);
      expect(controller.resumed, isFalse);
    });

    testWidgets('실행 중인데 남은 시간이 0이면 완료와 5분 연장만 보여 준다', (tester) async {
      final timer = makeTimer(
        id: 'timer-1',
        status: TimerStatus.running,
        startedAt: DateTime.utc(2026, 11, 5, 23, 59),
        allocatedDuration: 60,
        elapsedTime: 0,
      );

      await _pumpTimerPage(
        tester,
        timer: timer,
        controller: _FakeTimerController(),
      );

      expectExtendOnly();
    });

    testWidgets('타이머 목록의 시간이 끝난 항목은 재개 대신 5분 연장을 보여 준다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: expired, controller: controller);

      final item = _historyItem('timer-1');
      final extend = find.descendant(
        of: item,
        matching: find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(extend, findsOneWidget);
      expect(
        find.descendant(of: item, matching: find.byTooltip('5분 연장')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: item, matching: find.byIcon(Icons.play_arrow)),
        findsNothing,
      );

      await tester.tap(extend);
      await tester.pump();

      expect(controller.extendedTimerId, 'timer-1');
      expect(controller.extendedBy, const Duration(minutes: 5));
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

    testWidgets('예정됨을 고르면 타이머 이벤트 없이 바로 예정됨으로 보여 주고 Todo 목록을 다시 읽는다', (
      tester,
    ) async {
      final scheduled = makeTodo().copyWith(status: TodoStatus.scheduled);
      when(
        () => todosApi.updateTodoV1TodosTodoIdPatch(
          todoId: any(named: 'todoId'),
          body: any(named: 'body'),
          timezone: any(named: 'timezone'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => scheduled);
      // 실시간 이벤트 없이 REST로 받은 활성 타이머만 가진다
      final repository = FakeTimerRepository()
        ..listActive = () async => [withTodo(TimerStatus.paused)];
      var todoListReads = 0;

      await tester.pumpWidget(
        pumpApp(
          const TimerPage(),
          overrides: [
            timerFriendActivityProvider.overrideWith(
              (ref) => const Stream<TimerWsTimerEvent>.empty(),
            ),
            timerRepositoryProvider.overrideWithValue(repository),
            timerWsClientProvider.overrideWithValue(null),
            currentUserProvider.overrideWithValue(null),
            timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
            timerTickerProvider.overrideWith(
              (ref) => Stream.value(const Duration(minutes: 60)),
            ),
            timerControllerProvider.overrideWith(_FakeTimerController.new),
            todosApiProvider.overrideWithValue(todosApi),
            todosProvider.overrideWith((ref, groupId) async {
              todoListReads++;
              return <TodoRead>[];
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();
      // 열려 있는 Todo 목록
      ProviderScope.containerOf(
        tester.element(find.byType(TimerPage)),
      ).listen(todosProvider(null), (_, _) {});
      await tester.pumpAndSettle();
      expect(todoListReads, 1);

      await tester.tap(find.byType(TodoStatusSelector));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(PopupMenuItem<TodoStatus>),
          matching: find.text(TodoStatus.scheduled.label),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(TodoStatusSelector),
          matching: find.byIcon(TodoStatus.scheduled.icon),
        ),
      );
      expect(
        icon.color,
        TodoStatus.scheduled.color(tester.element(find.byType(TimerPage))),
      );
      expect(todoListReads, 2);
      expect(repository.calls, ['list']);
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

    for (final (text, seconds) in [('007', 7 * 60), ('600', 600 * 60)]) {
      testWidgets('분 "$text"도 그 값으로 시작한다', (tester) async {
        final controller = _FakeTimerController();

        await _pumpTimerPage(tester, timer: null, controller: controller);
        await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), text);
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, '시작'));
        await tester.pumpAndSettle();

        expect(controller.startedAllocatedDurationSeconds, seconds);
      });
    }

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

  group('다이얼', () {
    Future<void> dragDialTo9(WidgetTester tester) async {
      final dial = find.byType(TimerDial);
      final center = tester.getCenter(dial);
      final size = tester.getSize(dial);
      final radius =
          (size.width < size.height ? size.width : size.height) * 0.4;
      await tester.dragFrom(
        center + Offset(0, -radius),
        Offset(-radius, radius),
      );
      await tester.pump();
    }

    testWidgets('활성 타이머가 없으면 다이얼을 끌어 고른 시간으로 새 작업을 연다', (tester) async {
      final controller = _FakeTimerController();

      await _pumpTimerPage(tester, timer: null, controller: controller);
      expect(find.byType(TimerDial), findsOneWidget);
      expect(_clockText(tester), '00:25:00');

      await dragDialTo9(tester);
      expect(_clockText(tester), '00:45:00');

      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller
            ?.text,
        '45',
      );
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '45분'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('실행 중인 타이머의 다이얼은 끌어도 남은 시간이 그대로다', (tester) async {
      final timer = makeTimer(
        id: 'timer-1',
        status: TimerStatus.running,
        allocatedDuration: 25 * 60,
        elapsedTime: 5 * 60,
      );

      await _pumpTimerPage(
        tester,
        timer: timer,
        controller: _FakeTimerController(),
      );
      expect(_clockText(tester), '00:20:00');

      await dragDialTo9(tester);

      expect(_clockText(tester), '00:20:00');
    });

    testWidgets('60분을 넘는 타이머의 판은 할당 시간 기준이다', (tester) async {
      final timer = makeTimer(
        id: 'timer-1',
        status: TimerStatus.running,
        allocatedDuration: 90 * 60,
        elapsedTime: 40 * 60,
      );

      await _pumpTimerPage(
        tester,
        timer: timer,
        controller: _FakeTimerController(),
      );

      final dial = tester.widget<TimerDial>(find.byType(TimerDial));
      expect(dial.face, const Duration(minutes: 120));
      expect(dial.remaining, const Duration(minutes: 50));
    });

    testWidgets('시간이 끝나면 다이얼은 에러 색이다', (tester) async {
      final timeUp = makeTimer(
        id: 'timer-1',
        status: TimerStatus.running,
        allocatedDuration: 600,
        elapsedTime: 600,
      );
      await _pumpTimerPage(
        tester,
        timer: timeUp,
        controller: _FakeTimerController(),
      );

      final cs = Theme.of(tester.element(find.byType(TimerDial))).colorScheme;
      expect(tester.widget<TimerDial>(find.byType(TimerDial)).color, cs.error);
    });

    testWidgets('일시정지면 다이얼은 반투명 primary다', (tester) async {
      final paused = makeTimer(
        id: 'timer-1',
        status: TimerStatus.paused,
        allocatedDuration: 600,
        elapsedTime: 100,
      );
      await _pumpTimerPage(
        tester,
        timer: paused,
        controller: _FakeTimerController(),
      );

      final cs = Theme.of(tester.element(find.byType(TimerDial))).colorScheme;
      final color = tester.widget<TimerDial>(find.byType(TimerDial)).color;
      expect(color.a, closeTo(0.5, 0.01));
      expect(color.withValues(alpha: 1), cs.primary.withValues(alpha: 1));
    });

    testWidgets('새 작업 다이얼로그를 취소해도 고른 시간이 남는다', (tester) async {
      await _pumpTimerPage(
        tester,
        timer: null,
        controller: _FakeTimerController(),
      );
      await dragDialTo9(tester);
      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      expect(_clockText(tester), '00:45:00');
    });
  });

  group('휴식', () {
    late DateTime breakNow;

    setUp(() => breakNow = DateTime(2026, 11, 9, 10));

    final paused = makeTimer(
      id: 'timer-1',
      status: TimerStatus.paused,
      allocatedDuration: 25 * 60,
      elapsedTime: 5 * 60,
    );

    Future<_FakeTimerController> pump(
      WidgetTester tester, {
      TimerRead? timer,
      _FakeTimerController? controller,
    }) async {
      final timerController = controller ?? _FakeTimerController();
      await _pumpTimerPage(
        tester,
        timer: timer,
        controller: timerController,
        overrides: [breakClockProvider.overrideWithValue(() => breakNow)],
      );
      return timerController;
    }

    Finder inDashboard(Finder finder) =>
        find.descendant(of: find.byType(TimerDashboard), matching: finder);

    Color? clockColor(WidgetTester tester) => tester
        .widget<Text>(
          find.descendant(
            of: find.byType(DigitalClock),
            matching: find.byType(Text),
          ),
        )
        .style
        ?.color;

    Future<void> chooseBreak(WidgetTester tester) async {
      await tester.tap(_mode('휴식'));
      await tester.pumpAndSettle();
    }

    Future<void> dragDialTo9(WidgetTester tester) async {
      final dial = find.byType(TimerDial);
      final center = tester.getCenter(dial);
      final size = tester.getSize(dial);
      final radius =
          (size.width < size.height ? size.width : size.height) * 0.4;
      await tester.dragFrom(
        center + Offset(0, -radius),
        Offset(-radius, radius),
      );
      await tester.pump();
    }

    testWidgets('대기 상태에서 휴식을 고르면 5분과 휴식 시작 버튼을 보여 준다', (tester) async {
      await pump(tester);

      expect(_modeSwitch(), findsOneWidget);
      expect(_clockText(tester), '00:25:00');

      await chooseBreak(tester);

      expect(_clockText(tester), '00:05:00');
      final start = _dashboardFabByIcon(Icons.coffee);
      expect(start, findsOneWidget);
      expect(
        find.descendant(of: start, matching: find.byTooltip('휴식 시작')),
        findsOneWidget,
      );
      expect(_dashboardFabByIcon(Icons.play_arrow), findsNothing);
      final cs = Theme.of(tester.element(find.byType(TimerDial))).colorScheme;
      expect(
        tester.widget<TimerDial>(find.byType(TimerDial)).color,
        cs.tertiary,
      );
    });

    testWidgets('휴식에서 다이얼을 끌면 휴식 시간만 바뀐다', (tester) async {
      await pump(tester);
      await chooseBreak(tester);

      await dragDialTo9(tester);
      expect(_clockText(tester), '00:45:00');

      await tester.tap(_mode('작업'));
      await tester.pumpAndSettle();
      expect(_clockText(tester), '00:25:00');

      await chooseBreak(tester);
      expect(_clockText(tester), '00:45:00');
    });

    testWidgets('휴식 시작은 서버에 보내지 않고 바로 휴식을 센다', (tester) async {
      final controller = await pump(tester);
      await chooseBreak(tester);
      final idleClock = clockColor(tester);

      await tester.tap(_dashboardFabByIcon(Icons.coffee));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(controller.started, isFalse);
      expect(inDashboard(find.text('휴식')), findsOneWidget);
      expect(_modeSwitch(), findsNothing);
      expect(_clockText(tester), '00:05:00');
      final stop = _dashboardFabByIcon(Icons.stop);
      expect(stop, findsOneWidget);
      expect(
        find.descendant(of: stop, matching: find.byTooltip('휴식 끝내기')),
        findsOneWidget,
      );
      expect(inDashboard(find.text('휴식 종료')), findsNothing);

      breakNow = breakNow.add(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));

      expect(_clockText(tester), '00:04:30');
      // 대기 시계처럼 흐리게 두지 않는다
      expect(clockColor(tester), isNot(idleClock));
    });

    testWidgets('휴식 시간이 끝나면 휴식 종료와 확인을 보여 주고 확인하면 대기 상태로 돌아간다', (tester) async {
      await pump(tester);
      await chooseBreak(tester);
      await tester.tap(_dashboardFabByIcon(Icons.coffee));
      await tester.pumpAndSettle();

      breakNow = breakNow.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));

      expect(_clockText(tester), '00:00:00');
      expect(inDashboard(find.text('휴식 종료')), findsOneWidget);
      expect(_dashboardFabByIcon(Icons.stop), findsNothing);
      final confirm = _dashboardFabByIcon(Icons.check);
      expect(confirm, findsOneWidget);
      expect(
        find.descendant(of: confirm, matching: find.byTooltip('확인')),
        findsOneWidget,
      );

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(inDashboard(find.text('휴식 종료')), findsNothing);
      expect(_modeSwitch(), findsOneWidget);
      expect(_dashboardFabByIcon(Icons.coffee), findsOneWidget);
      expect(_clockText(tester), '00:05:00');
    });

    testWidgets('일시정지한 타이머에서 휴식을 시작하고 끝내면 그 타이머로 돌아간다', (tester) async {
      final controller = await pump(tester, timer: paused);

      final rest = _dashboardFabByIcon(Icons.coffee);
      expect(rest, findsOneWidget);
      expect(
        find.descendant(of: rest, matching: find.byTooltip('휴식')),
        findsOneWidget,
      );

      await tester.tap(rest);
      await tester.pumpAndSettle();

      expect(inDashboard(find.text('휴식')), findsOneWidget);
      expect(inDashboard(find.text('일시정지')), findsNothing);
      expect(_clockText(tester), '00:05:00');
      expect(_dashboardFabByIcon(Icons.play_arrow), findsNothing);

      await tester.tap(_dashboardFabByIcon(Icons.stop));
      await tester.pumpAndSettle();

      expect(inDashboard(find.text('휴식')), findsNothing);
      expect(inDashboard(find.text('일시정지')), findsOneWidget);
      expect(_clockText(tester), '00:20:00');
      expect(_dashboardFabByIcon(Icons.play_arrow), findsOneWidget);
      expect(_dashboardFabByIcon(Icons.coffee), findsOneWidget);
      expect(controller.resumed, isFalse);
    });

    for (final (name, timer, control) in [
      (
        '실행 중인',
        makeTimer(id: 'timer-1', status: TimerStatus.running),
        Icons.pause,
      ),
      (
        '시간이 끝난',
        makeTimer(
          id: 'timer-1',
          status: TimerStatus.paused,
          allocatedDuration: 25 * 60,
          elapsedTime: 25 * 60,
        ),
        Icons.add,
      ),
    ]) {
      testWidgets('일시정지 타이머가 $name 타이머가 되면 휴식 버튼이 사라지고 작업·휴식 선택도 없다', (
        tester,
      ) async {
        final controller = await pump(tester, timer: paused);
        expect(_dashboardFabByIcon(Icons.coffee), findsOneWidget);

        await pump(tester, timer: timer, controller: controller);

        expect(_dashboardFabByIcon(control), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.coffee), findsNothing);
        expect(_modeSwitch(), findsNothing);
      });
    }

    testWidgets('휴식 중에 타이머가 실행되면 휴식이 끝나고 그 타이머를 보여 준다', (tester) async {
      final controller = await pump(tester, timer: paused);
      await tester.tap(_dashboardFabByIcon(Icons.coffee));
      await tester.pumpAndSettle();
      expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);

      // 같은 override로 다시 그리면 활성 타이머 값만 바뀐다 (다른 기기에서 재개)
      await pump(
        tester,
        timer: paused.copyWith(status: TimerStatus.running),
        controller: controller,
      );

      expect(inDashboard(find.text('휴식')), findsNothing);
      expect(_dashboardFabByIcon(Icons.stop), findsNothing);
      expect(_dashboardFabByIcon(Icons.pause), findsOneWidget);
    });

    group('경계', () {
      void setSize(WidgetTester tester, Size size) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
      }

      Future<void> startBreak(WidgetTester tester) async {
        await chooseBreak(tester);
        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();
      }

      TimerDial dial(WidgetTester tester) =>
          tester.widget<TimerDial>(find.byType(TimerDial));

      testWidgets(
        '작업·휴식 칸에 아이콘이 있고 다이얼은 작업이 primary, 휴식이 tertiary이며 대기 시계 색은 같다',
        (tester) async {
          await pump(tester);
          final cs = Theme.of(
            tester.element(find.byType(TimerDial)),
          ).colorScheme;

          expect(
            find.descendant(
              of: _modeSwitch(),
              matching: find.byIcon(Icons.coffee_outlined),
            ),
            findsOneWidget,
          );
          expect(dial(tester).color, cs.primary);
          final idleClock = clockColor(tester);

          await chooseBreak(tester);

          expect(
            find.descendant(
              of: _modeSwitch(),
              matching: find.byIcon(Icons.timer_outlined),
            ),
            findsOneWidget,
          );
          expect(dial(tester).color, cs.tertiary);
          expect(clockColor(tester), idleClock);

          await tester.tap(_mode('작업'));
          await tester.pumpAndSettle();

          expect(dial(tester).color, cs.primary);
        },
      );

      testWidgets('고른 칸을 다시 눌러도 선택이 풀리지 않는다', (tester) async {
        await pump(tester);

        await tester.tap(_mode('작업'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_dashboardFabByIcon(Icons.play_arrow), findsOneWidget);
        expect(_clockText(tester), '00:25:00');

        await chooseBreak(tester);
        await chooseBreak(tester);

        expect(tester.takeException(), isNull);
        expect(_dashboardFabByIcon(Icons.coffee), findsOneWidget);
        expect(_clockText(tester), '00:05:00');
      });

      testWidgets('휴식에서 고른 시간은 새 작업 시간에 섞이지 않는다', (tester) async {
        final controller = await pump(tester);
        await chooseBreak(tester);
        await dragDialTo9(tester);

        await tester.tap(_mode('작업'));
        await tester.pumpAndSettle();
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

      testWidgets('작업에서 고른 시간은 휴식 시간에 섞이지 않는다', (tester) async {
        await pump(tester);
        await dragDialTo9(tester);
        expect(_clockText(tester), '00:45:00');

        await startBreak(tester);

        expect(_clockText(tester), '00:05:00');
        expect(dial(tester).remaining, const Duration(minutes: 5));
      });

      testWidgets('다이얼 끝까지 고른 60분 휴식은 01:00:00부터 센다', (tester) async {
        await pump(tester);
        await chooseBreak(tester);
        final center = tester.getCenter(find.byType(TimerDial));
        final size = tester.getSize(find.byType(TimerDial));
        final radius =
            (size.width < size.height ? size.width : size.height) * 0.4;

        // 9시에서 12시 바로 왼쪽까지 끈다
        await tester.dragFrom(
          center + Offset(-radius, 0),
          Offset(radius * 0.97, -radius),
        );
        await tester.pump();

        expect(_clockText(tester), '01:00:00');

        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();

        expect(_clockText(tester), '01:00:00');
        expect(dial(tester).remaining, const Duration(minutes: 60));
      });

      testWidgets('휴식을 시작한 첫 프레임부터 남은 시간을 보이고 휴식 종료를 비추지 않는다', (tester) async {
        await pump(tester);
        await chooseBreak(tester);

        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pump();

        expect(_clockText(tester), '00:05:00');
        expect(inDashboard(find.text('휴식 종료')), findsNothing);
        expect(_dashboardFabByIcon(Icons.check), findsNothing);
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
      });

      testWidgets('끝나기 직전까지는 1초를 보이고 끝나는 순간 휴식 종료로 바뀐다', (tester) async {
        await pump(tester);
        await startBreak(tester);

        breakNow = breakNow.add(
          const Duration(minutes: 4, seconds: 59, milliseconds: 999),
        );
        await tester.pump(const Duration(seconds: 1));

        expect(_clockText(tester), '00:00:01');
        expect(dial(tester).remaining, const Duration(seconds: 1));
        expect(inDashboard(find.text('휴식 종료')), findsNothing);
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);

        breakNow = breakNow.add(const Duration(milliseconds: 1));
        await tester.pump(const Duration(seconds: 1));

        expect(_clockText(tester), '00:00:00');
        expect(dial(tester).remaining, Duration.zero);
        expect(inDashboard(find.text('휴식 종료')), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.stop), findsNothing);
        expect(_dashboardFabByIcon(Icons.check), findsOneWidget);
      });

      testWidgets('휴식 중 다이얼은 tertiary로 남은 휴식을 보이고 끌어도 휴식 값이 그대로다', (
        tester,
      ) async {
        await pump(tester);
        await startBreak(tester);
        breakNow = breakNow.add(const Duration(seconds: 30));
        await tester.pump(const Duration(seconds: 1));

        final cs = Theme.of(tester.element(find.byType(TimerDial))).colorScheme;
        final shown = dial(tester);
        expect(shown.onChanged, isNull);
        expect(shown.color, cs.tertiary);
        expect(shown.remaining, const Duration(minutes: 4, seconds: 30));
        expect(
          shown.face ?? dialFaceFor(shown.remaining),
          dialFaceFor(const Duration(minutes: 5)),
        );

        await dragDialTo9(tester);

        expect(_clockText(tester), '00:04:30');

        await tester.tap(_dashboardFabByIcon(Icons.stop));
        await tester.pumpAndSettle();

        expect(_clockText(tester), '00:05:00');
      });

      testWidgets('휴식 시작과 확인을 한 프레임 안에 두 번 눌러도 휴식은 하나고 확인 뒤 새 휴식은 없다', (
        tester,
      ) async {
        final controller = await pump(tester);
        await chooseBreak(tester);

        final start = _dashboardFabByIcon(Icons.coffee);
        await tester.tap(start);
        await tester.tap(start);
        await tester.pump();

        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
        expect(_clockText(tester), '00:05:00');

        breakNow = breakNow.add(const Duration(minutes: 5));
        await tester.pump(const Duration(seconds: 1));
        final confirm = _dashboardFabByIcon(Icons.check);
        await tester.tap(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        expect(_modeSwitch(), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.coffee), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.stop), findsNothing);
        expect(controller.started, isFalse);
      });

      testWidgets('일시정지 타이머의 휴식 버튼은 대기에서 고른 휴식 시간으로 시작한다', (tester) async {
        final controller = await pump(tester);
        await chooseBreak(tester);
        await dragDialTo9(tester);

        // 다른 기기에서 시작해 일시정지한 타이머
        await pump(tester, timer: paused, controller: controller);
        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();

        expect(inDashboard(find.text('휴식')), findsOneWidget);
        expect(_clockText(tester), '00:45:00');
      });

      testWidgets('같은 일시정지 타이머를 다시 받아도 휴식은 그대로다', (tester) async {
        final controller = await pump(tester, timer: paused);
        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();

        // 태그만 바꾼 PATCH 같은 이벤트
        await pump(
          tester,
          timer: paused.copyWith(updatedAt: DateTime.utc(2026, 1, 1, 0, 1)),
          controller: controller,
        );

        expect(inDashboard(find.text('휴식')), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
      });

      testWidgets('휴식 중에 다른 기기에서 일시정지 타이머가 생겨도 휴식을 보이고 끝내면 그 타이머를 보인다', (
        tester,
      ) async {
        final controller = await pump(tester);
        await startBreak(tester);

        await pump(tester, timer: paused, controller: controller);

        expect(inDashboard(find.text('휴식')), findsOneWidget);
        expect(inDashboard(find.text('일시정지')), findsNothing);
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.play_arrow), findsNothing);
        expect(_clockText(tester), '00:05:00');

        await tester.tap(_dashboardFabByIcon(Icons.stop));
        await tester.pumpAndSettle();

        expect(inDashboard(find.text('일시정지')), findsOneWidget);
        expect(_clockText(tester), '00:20:00');
        expect(_dashboardFabByIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('휴식 중에 일시정지 타이머가 다른 곳에서 완료돼도 휴식은 이어지고 끝내면 대기 상태다', (
        tester,
      ) async {
        final controller = await pump(tester, timer: paused);
        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();

        await pump(tester, timer: null, controller: controller);

        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
        expect(_clockText(tester), '00:05:00');

        await tester.tap(_dashboardFabByIcon(Icons.stop));
        await tester.pumpAndSettle();

        expect(_modeSwitch(), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.play_arrow), findsOneWidget);
        expect(_clockText(tester), '00:25:00');
      });

      testWidgets('일시정지 타이머 위의 휴식이 0이 되면 확인만 보이고 확인하면 완료 없이 그 타이머로 돌아간다', (
        tester,
      ) async {
        final controller = await pump(tester, timer: paused);
        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();

        breakNow = breakNow.add(const Duration(minutes: 5));
        await tester.pump(const Duration(seconds: 1));

        expect(inDashboard(find.text('휴식 종료')), findsOneWidget);
        expect(inDashboard(find.text('일시정지')), findsNothing);
        expect(inDashboard(find.byType(FloatingActionButton)), findsOneWidget);

        await tester.tap(_dashboardFabByIcon(Icons.check));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(controller.stopCalled, isFalse);
        expect(inDashboard(find.text('일시정지')), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('Todo가 연결된 일시정지 타이머에서 휴식하면 제목 줄에 휴식만 보인다', (tester) async {
        await pump(
          tester,
          timer: paused.copyWith(
            title: '보고서 쓰기',
            todoId: 'todo-1',
            todo: makeTodo(),
          ),
        );
        expect(find.byType(TodoStatusSelector), findsOneWidget);

        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();

        expect(inDashboard(find.text('휴식')), findsOneWidget);
        expect(find.byType(TodoStatusSelector), findsNothing);
        expect(
          inDashboard(find.byIcon(TodoStatus.unscheduled.icon)),
          findsNothing,
        );
        expect(inDashboard(find.text('보고서 쓰기')), findsNothing);
        expect(inDashboard(find.text('테스트 할 일')), findsNothing);
      });

      testWidgets('창 폭이 600을 넘나들어도 고른 모드와 휴식 시간, 진행 중인 휴식이 남는다', (
        tester,
      ) async {
        setSize(tester, const Size(1280, 800));
        await pump(tester);
        await chooseBreak(tester);
        await dragDialTo9(tester);

        tester.view.physicalSize = const Size(360, 800);
        await tester.pumpAndSettle();

        expect(find.byType(TimerHistoryList), findsNothing);
        expect(_dashboardFabByIcon(Icons.coffee), findsOneWidget);
        expect(_clockText(tester), '00:45:00');

        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();
        breakNow = breakNow.add(const Duration(minutes: 1));
        tester.view.physicalSize = const Size(1280, 800);
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(TimerHistoryList), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
        expect(_clockText(tester), '00:44:00');
      });

      testWidgets('타이머 화면을 떠났다 돌아와도 휴식이 이어진다', (tester) async {
        final controller = await pump(tester);
        await startBreak(tester);

        await tester.pumpWidget(
          pumpApp(
            const SizedBox(),
            overrides: [
              ..._timerOverrides(
                timer: null,
                history: [],
                controller: controller,
              ),
              breakClockProvider.overrideWithValue(() => breakNow),
            ],
          ),
        );
        expect(find.byType(TimerPage), findsNothing);
        breakNow = breakNow.add(const Duration(minutes: 2));
        await tester.pump(const Duration(seconds: 1));

        await pump(tester, controller: controller);

        expect(inDashboard(find.text('휴식')), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
        expect(_clockText(tester), '00:03:00');
      });

      testWidgets('다른 탭에 있는 사이 타이머가 실행됐다가 다시 일시정지해도 돌아오면 휴식이 끝나 있다', (
        tester,
      ) async {
        final controller = _FakeTimerController();
        // 다른 탭으로 가면 StatefulShellRoute가 타이머 탭의 TickerMode를 끄고, 화면의 구독이 멈춘다
        Future<void> show(TimerRead timer, {required bool visible}) async {
          await tester.pumpWidget(
            pumpApp(
              TickerMode(enabled: visible, child: const TimerPage()),
              overrides: [
                ..._timerOverrides(
                  timer: timer,
                  history: [timer],
                  controller: controller,
                ),
                breakClockProvider.overrideWithValue(() => breakNow),
              ],
            ),
          );
          await tester.pumpAndSettle();
        }

        await show(paused, visible: true);
        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);

        await show(paused, visible: false);
        await show(
          paused.copyWith(
            status: TimerStatus.running,
            updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
          ),
          visible: false,
        );
        final pausedAgain = paused.copyWith(
          updatedAt: DateTime.utc(2026, 1, 1, 0, 2),
        );
        await show(pausedAgain, visible: false);
        await show(pausedAgain, visible: true);

        expect(inDashboard(find.text('휴식')), findsNothing);
        expect(inDashboard(find.text('일시정지')), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('좁은 화면의 타이머 목록 시트에 휴식은 나오지 않는다', (tester) async {
        setSize(tester, const Size(360, 800));
        await pump(tester, timer: paused);
        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithIcon(IconButton, Icons.history));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(TimerHistoryItem), findsOneWidget);
        expect(_historyItem('timer-1'), findsOneWidget);
      });

      // 대기에서는 0까지 기다려 확인하고, 일시정지 타이머에서는 세는 중에 끝낸다
      for (final (label, timer, finish) in [
        ('대기', null, Icons.check),
        ('일시정지 타이머', paused, Icons.stop),
      ]) {
        testWidgets('$label에서 휴식을 시작하고 끝내도 서버에 아무것도 보내지 않는다', (tester) async {
          final repository = FakeTimerRepository()
            ..listActive = () async => [?timer];
          await tester.pumpWidget(
            pumpApp(
              const TimerPage(),
              overrides: [
                timerFriendActivityProvider.overrideWith(
                  (ref) => const Stream<TimerWsTimerEvent>.empty(),
                ),
                timerRepositoryProvider.overrideWithValue(repository),
                timerWsClientProvider.overrideWithValue(null),
                currentUserProvider.overrideWithValue(null),
                timerHistoryProvider.overrideWith((ref) async => [?timer]),
                timerTickerProvider.overrideWith(
                  (ref) => Stream.value(const Duration(minutes: 20)),
                ),
                breakClockProvider.overrideWithValue(() => breakNow),
              ],
            ),
          );
          await tester.pumpAndSettle();
          expect(repository.calls, ['list']);

          if (timer == null) await chooseBreak(tester);
          await tester.tap(_dashboardFabByIcon(Icons.coffee));
          await tester.pumpAndSettle();
          if (finish == Icons.check) {
            breakNow = breakNow.add(const Duration(minutes: 5));
          }
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(_dashboardFabByIcon(finish));
          await tester.pumpAndSettle();

          expect(find.byType(AlertDialog), findsNothing);
          expect(_dashboardFabByIcon(Icons.stop), findsNothing);
          expect(inDashboard(find.text('휴식 종료')), findsNothing);
          expect(repository.calls, ['list']);
        });
      }

      testWidgets('타이머가 실행됐다 끝나 대기로 돌아와도 고른 모드와 시간이 그대로다', (tester) async {
        final controller = await pump(tester);
        await chooseBreak(tester);
        await dragDialTo9(tester);

        await pump(
          tester,
          timer: makeTimer(id: 'timer-1', status: TimerStatus.running),
          controller: controller,
        );
        expect(_modeSwitch(), findsNothing);

        await pump(tester, timer: null, controller: controller);

        expect(_dashboardFabByIcon(Icons.coffee), findsOneWidget);
        expect(_clockText(tester), '00:45:00');
      });

      testWidgets('활성 타이머를 읽는 중이어도 휴식이 있으면 휴식을 보인다', (tester) async {
        await tester.pumpWidget(
          pumpApp(
            const TimerPage(),
            overrides: [
              timerFriendActivityProvider.overrideWith(
                (ref) => const Stream<TimerWsTimerEvent>.empty(),
              ),
              activeTimerProvider.overrideWithValue(const AsyncLoading()),
              timerHistoryProvider.overrideWith(
                (ref) => Future.value(<TimerRead>[]),
              ),
              timerTickerProvider.overrideWith(
                (ref) => Stream.value(Duration.zero),
              ),
              timerControllerProvider.overrideWith(_FakeTimerController.new),
              breakClockProvider.overrideWithValue(() => breakNow),
            ],
          ),
        );
        await tester.pump();

        ProviderScope.containerOf(
          tester.element(find.byType(TimerPage)),
        ).read(breakTimerProvider.notifier).start(const Duration(minutes: 5));
        await tester.pump();
        await tester.pump();

        expect(inDashboard(find.text('휴식')), findsOneWidget);
        expect(_dashboardFabByIcon(Icons.stop), findsOneWidget);
        expect(_clockText(tester), '00:05:00');
      });

      for (final size in const [
        Size(360, 800),
        Size(360, 560),
        Size(844, 390),
        Size(800, 1280),
        Size(1280, 800),
      ]) {
        final label = '${size.width.toInt()}x${size.height.toInt()}';

        testWidgets('$label 화면에서 작업·휴식 선택은 시계 아래, 제어 버튼 바로 위에 대시보드 안에 있다', (
          tester,
        ) async {
          setSize(tester, size);
          await pump(tester);

          expect(tester.takeException(), isNull);
          final dashboard = tester.getRect(find.byType(TimerDashboard));
          final modes = tester.getRect(_modeSwitch());
          final fab = tester.getRect(_dashboardFabByIcon(Icons.play_arrow));
          final clock = tester.getRect(find.byType(DigitalClock));

          expect(modes.left, greaterThanOrEqualTo(dashboard.left));
          expect(modes.right, lessThanOrEqualTo(dashboard.right));
          expect(modes.bottom, lessThanOrEqualTo(size.height));
          expect(clock.bottom, lessThanOrEqualTo(modes.top));
          expect(modes.bottom, lessThanOrEqualTo(fab.top));
        });
      }
    });
  });

  group('레이아웃', () {
    void setSize(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    final running = makeTimer(id: 'timer-1', status: TimerStatus.running);
    final historyAction = find.widgetWithIcon(IconButton, Icons.history);

    Finder inDashboard(Finder finder) =>
        find.descendant(of: find.byType(TimerDashboard), matching: finder);

    testWidgets('좁은 화면은 다이얼만 두고 앱 바에서 타이머 목록 시트를 연다', (tester) async {
      setSize(tester, const Size(360, 800));
      await _pumpTimerPage(
        tester,
        timer: running,
        controller: _FakeTimerController(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TimerDial), findsOneWidget);
      expect(find.byType(TimerHistoryList), findsNothing);
      expect(historyAction, findsOneWidget);
      expect(find.byTooltip('타이머 목록'), findsOneWidget);

      await tester.tap(historyAction);
      await tester.pumpAndSettle();

      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.byType(TimerHistoryList)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: _historyItem('timer-1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('넓은 화면은 다이얼 옆에 타이머 목록을 둔다', (tester) async {
      setSize(tester, const Size(1280, 800));
      await _pumpTimerPage(
        tester,
        timer: running,
        controller: _FakeTimerController(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TimerDial), findsOneWidget);
      expect(find.byType(TimerHistoryList), findsOneWidget);
      expect(historyAction, findsNothing);
      expect(
        tester.getCenter(find.byType(TimerHistoryList)).dx,
        greaterThan(tester.getCenter(find.byType(TimerDial)).dx),
      );
    });

    testWidgets('가로 휴대폰 화면에서도 넘치지 않고 제어 버튼이 보인다', (tester) async {
      setSize(tester, const Size(844, 390));
      await _pumpTimerPage(
        tester,
        timer: running,
        controller: _FakeTimerController(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TimerDial), findsOneWidget);
      expect(find.byType(TimerHistoryList), findsOneWidget);
      final pause = _dashboardFabByIcon(Icons.pause);
      expect(pause, findsOneWidget);
      expect(_dashboardFabByIcon(Icons.check), findsOneWidget);
      expect(tester.getRect(pause).bottom, lessThanOrEqualTo(390));
    });

    testWidgets('좁은 화면에서 시간이 끝난 타이머는 시간 종료와 연장 버튼을 보여 준다', (tester) async {
      setSize(tester, const Size(360, 800));
      await _pumpTimerPage(
        tester,
        timer: makeTimer(
          id: 'timer-1',
          status: TimerStatus.paused,
          allocatedDuration: 25 * 60,
          elapsedTime: 25 * 60,
        ),
        controller: _FakeTimerController(),
      );

      expect(tester.takeException(), isNull);
      expect(inDashboard(find.text('시간 종료')), findsOneWidget);
      expect(inDashboard(find.text('일시정지')), findsNothing);
      expect(_dashboardFabByIcon(Icons.add), findsOneWidget);
    });

    testWidgets('일시정지면 일시정지 캡션을 보여 준다', (tester) async {
      await _pumpTimerPage(
        tester,
        timer: makeTimer(
          id: 'timer-1',
          status: TimerStatus.paused,
          allocatedDuration: 25 * 60,
          elapsedTime: 5 * 60,
        ),
        controller: _FakeTimerController(),
      );

      expect(inDashboard(find.text('일시정지')), findsOneWidget);
      expect(inDashboard(find.text('시간 종료')), findsNothing);
    });

    testWidgets('실행 중이면 상태 캡션이 없다', (tester) async {
      await _pumpTimerPage(
        tester,
        timer: running,
        controller: _FakeTimerController(),
      );

      expect(inDashboard(find.text('일시정지')), findsNothing);
      expect(inDashboard(find.text('시간 종료')), findsNothing);
    });

    testWidgets('좁은 화면의 타이머 목록 시트에서 항목이 넘치지 않는다', (tester) async {
      setSize(tester, const Size(360, 800));
      final paused = makeTimer(
        id: 'timer-2',
        status: TimerStatus.paused,
      ).copyWith(title: '아주 긴 작업 이름이 들어가도 목록 항목이 넘치지 않아야 한다');
      await _pumpTimerPage(
        tester,
        timer: running,
        history: [running, paused],
        controller: _FakeTimerController(),
      );

      await tester.tap(historyAction);
      await tester.pumpAndSettle();

      expect(_historyItem('timer-1'), findsOneWidget);
      expect(_historyItem('timer-2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    Future<void> dragTo9(WidgetTester tester) async {
      final dial = find.byType(TimerDial);
      final center = tester.getCenter(dial);
      final size = tester.getSize(dial);
      final radius =
          (size.width < size.height ? size.width : size.height) * 0.4;
      await tester.dragFrom(
        center + Offset(0, -radius),
        Offset(-radius, radius),
      );
      await tester.pump();
    }

    testWidgets('좁은 화면의 대기 상태는 다이얼을 끌 수 있고 새 작업 다이얼로그가 넘치지 않는다', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      await _pumpTimerPage(
        tester,
        timer: null,
        controller: _FakeTimerController(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('진행 중인 작업이 없습니다'), findsOneWidget);
      await dragTo9(tester);
      expect(_clockText(tester), '00:45:00');

      await tester.tap(_dashboardFabByIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '45분'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('창 폭이 600을 넘나들어도 고른 시간이 남는다', (tester) async {
      setSize(tester, const Size(1280, 800));
      await _pumpTimerPage(
        tester,
        timer: null,
        controller: _FakeTimerController(),
      );
      await dragTo9(tester);
      expect(_clockText(tester), '00:45:00');

      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();

      expect(find.byType(TimerHistoryList), findsNothing);
      expect(_clockText(tester), '00:45:00');
    });

    testWidgets('아주 낮은 좁은 화면에서도 넘치지 않는다', (tester) async {
      setSize(tester, const Size(360, 560));
      await _pumpTimerPage(
        tester,
        timer: running,
        controller: _FakeTimerController(),
      );

      expect(tester.takeException(), isNull);
      expect(_dashboardFabByIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('태블릿 세로 화면의 목록 항목이 넘치지 않는다', (tester) async {
      setSize(tester, const Size(800, 1280));
      final long = makeTimer(
        id: 'timer-2',
        status: TimerStatus.paused,
      ).copyWith(title: '아주 긴 작업 이름이 들어가도 목록 항목이 넘치지 않아야 한다');
      await _pumpTimerPage(
        tester,
        timer: running,
        history: [running, long],
        controller: _FakeTimerController(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TimerHistoryList), findsOneWidget);
      expect(_historyItem('timer-2'), findsOneWidget);
    });

    for (final size in const [
      Size(360, 800),
      Size(360, 560),
      Size(844, 390),
      Size(800, 1280),
      Size(1280, 800),
    ]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      /// 넘침 없이 [fab]이 화면 안에 하나 있다
      void expectFits(WidgetTester tester, Finder fab) {
        expect(tester.takeException(), isNull);
        expect(fab, findsOneWidget);
        expect(tester.getRect(fab).bottom, lessThanOrEqualTo(size.height));
      }

      testWidgets('$label 화면에서 대기·휴식 중·휴식 종료가 넘치지 않는다', (tester) async {
        setSize(tester, size);
        var breakNow = DateTime(2026, 11, 9, 10);
        await _pumpTimerPage(
          tester,
          timer: null,
          controller: _FakeTimerController(),
          overrides: [breakClockProvider.overrideWithValue(() => breakNow)],
        );

        expect(_modeSwitch(), findsOneWidget);
        expectFits(tester, _dashboardFabByIcon(Icons.play_arrow));

        await tester.tap(_mode('휴식'));
        await tester.pumpAndSettle();
        expectFits(tester, _dashboardFabByIcon(Icons.coffee));

        await tester.tap(_dashboardFabByIcon(Icons.coffee));
        await tester.pumpAndSettle();
        expectFits(tester, _dashboardFabByIcon(Icons.stop));

        breakNow = breakNow.add(const Duration(minutes: 5));
        await tester.pump(const Duration(seconds: 1));
        expect(inDashboard(find.text('휴식 종료')), findsOneWidget);
        expectFits(tester, _dashboardFabByIcon(Icons.check));
      });

      testWidgets('$label 화면에서 일시정지 타이머의 버튼 세 개가 넘치지 않는다', (tester) async {
        setSize(tester, size);
        await _pumpTimerPage(
          tester,
          timer: makeTimer(
            id: 'timer-1',
            status: TimerStatus.paused,
            allocatedDuration: 25 * 60,
            elapsedTime: 5 * 60,
          ),
          controller: _FakeTimerController(),
        );

        for (final icon in [Icons.check, Icons.play_arrow, Icons.coffee]) {
          expectFits(tester, _dashboardFabByIcon(icon));
        }
      });
    }
  });

  group('타이머 목록 항목', () {
    for (final status in [TimerStatus.running, TimerStatus.paused]) {
      testWidgets('360 폭에서 ${status.name} 항목이 넘치지 않는다', (tester) async {
        final timer = makeTimer(
          id: 'timer-1',
          status: status,
        ).copyWith(title: '아주 긴 작업 이름이 들어가도 목록 항목이 넘치지 않아야 한다');

        await tester.pumpWidget(
          pumpApp(
            Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 360,
                  child: TimerHistoryItem(timer: timer),
                ),
              ),
            ),
            overrides: _timerOverrides(
              timer: timer,
              history: [timer],
              controller: _FakeTimerController(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(TimerHistoryItem), findsOneWidget);
      });
    }
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
    // 다시 그려 활성 타이머가 바뀌면 남은 시간도 따라 바뀐다
    timerTickerProvider.overrideWith((ref) {
      final active = ref.watch(activeTimerProvider).value;
      return Stream.value(
        active == null
            ? Duration.zero
            : displayRemaining(active, DateTime.utc(2026, 11, 6)),
      );
    }),
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

/// 대기 상태의 작업·휴식 선택
Finder _modeSwitch() =>
    find.byWidgetPredicate((widget) => widget is SegmentedButton);

/// 작업·휴식 선택에서 [label] 칸
Finder _mode(String label) =>
    find.descendant(of: _modeSwitch(), matching: find.text(label));

Finder _historyCompleteButton() {
  final iconInButton = find.descendant(
    of: find.byType(IconButton),
    matching: find.byIcon(Icons.check),
  );
  return find.ancestor(of: iconInButton, matching: find.byType(IconButton));
}

class _MockTodosClient extends Mock implements TodosClient {}

/// 명령 응답을 기다리는(로딩) 컨트롤러
class _LoadingTimerController extends _FakeTimerController {
  @override
  FutureOr<void> build() => Completer<void>().future;
}

class _FixedViews extends TimerViewsNotifier {
  _FixedViews(this.views);

  final Map<String, TimerRead> views;

  @override
  Map<String, TimerRead> build() => views;
}

class _FakeTimerController extends TimerController {
  bool stopCalled = false;
  String? stoppedTimerId;
  bool started = false;
  int? startedAllocatedDurationSeconds;
  bool paused = false;
  bool resumed = false;
  Duration? extendedBy;
  String? extendedTimerId;

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
  Future<void> extendTimer({String? timerId, required Duration by}) async {
    extendedTimerId = timerId;
    extendedBy = by;
  }

  @override
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    started = true;
    startedAllocatedDurationSeconds = allocatedDurationSeconds;
  }
}
