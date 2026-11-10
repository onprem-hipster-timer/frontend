import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/widgets/current_task_display.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_list.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item.dart';
import 'package:momeet/features/timer/presentation/widgets/shared_timer_item.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/providers/friend_providers.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 타이머 화면의 공유 버튼·친구 타이머 경계. 기본 동작은 timer_page_test.dart의 '공유 설정'·'친구 타이머'
void main() {
  final now = DateTime.utc(2026, 11, 9, 10);
  const long = '아주 긴 작업 이름이 들어가도 넘치지 않아야 하는 타이머 제목';

  late FakeTimerRepository repository;
  late DateTime clock;

  setUp(() {
    repository = FakeTimerRepository();
    clock = now;
  });

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  String sizeLabel(Size size) => '${size.width.toInt()}x${size.height.toInt()}';

  final share = find.byTooltip('공유 설정');
  Finder dashboardShare() =>
      find.descendant(of: find.byType(CurrentTaskDisplay), matching: share);
  Finder historyItem(String timerId) => find.byWidgetPredicate(
    (widget) => widget is TimerHistoryItem && widget.timer.id == timerId,
  );
  Finder itemShare(String timerId) =>
      find.descendant(of: historyItem(timerId), matching: share);
  Finder sheet() => find.byType(BottomSheet);
  Finder historySheetList() =>
      find.descendant(of: sheet(), matching: find.byType(TimerHistoryList));

  IconData? iconOf(WidgetTester tester, Finder finder) => tester
      .widget<Icon>(find.descendant(of: finder, matching: find.byType(Icon)))
      .icon;

  Finder dashboardFab(IconData icon) => find.ancestor(
    of: find.descendant(
      of: find.byType(FloatingActionButton),
      matching: find.byIcon(icon),
    ),
    matching: find.byType(FloatingActionButton),
  );

  List<Override> common({
    Future<List<FriendRead>> Function()? friends,
    Stream<TimerWsTimerEvent> friendActivity = const Stream.empty(),
  }) => [
    allTodosProvider.overrideWith((ref) async => const <TodoRead>[]),
    timerFriendActivityProvider.overrideWith((ref) => friendActivity),
    timerRepositoryProvider.overrideWithValue(repository),
    timerWsClientProvider.overrideWithValue(null),
    currentUserProvider.overrideWithValue(null),
    friendsProvider.overrideWith(
      (ref) => (friends ?? () async => <FriendRead>[])(),
    ),
    serverClockProvider.overrideWithValue(ServerClock(deviceNow: () => clock)),
  ];

  /// 활성 타이머를 [active]로 고정해 타이머 화면을 그린다
  Future<void> pumpFixed(
    WidgetTester tester, {
    required TimerRead? active,
    List<TimerRead>? history,
    Object? historyError,
    Future<List<FriendRead>> Function()? friends,
    Stream<TimerWsTimerEvent> friendActivity = const Stream.empty(),
  }) async {
    await tester.pumpWidget(
      pumpApp(
        const TimerPage(),
        overrides: [
          ...common(friends: friends, friendActivity: friendActivity),
          activeTimerProvider.overrideWithValue(AsyncData(active)),
          // 휴식이 보는 내 활성 타이머 목록은 고정한 활성 타이머 하나로 맞춘다
          myActiveTimersProvider.overrideWithBuild(
            (ref, _) => [?ref.watch(activeTimerProvider).value],
          ),
          timerHistoryProvider.overrideWith((ref) async {
            if (historyError != null) throw historyError;
            return history ?? [?active];
          }),
          timerTickerProvider.overrideWith(
            (ref) => Stream.value(
              active == null ? Duration.zero : displayRemaining(active, clock),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 활성 타이머를 실제 [myActiveTimersProvider]로 두고 타이머 화면을 그린다.
  /// 활성 타이머 목록은 [FakeTimerRepository.listActive], 타이머 목록은 [history]가 읽을 때마다 준다
  Future<ProviderContainer> pumpLive(
    WidgetTester tester, {
    required List<TimerRead> Function() history,
  }) async {
    await tester.pumpWidget(
      pumpApp(
        const TimerPage(),
        overrides: [
          ...common(
            friends: () async => [makeFriend('friend-1', displayName: '영희')],
          ),
          timerHistoryProvider.overrideWith((ref) async => history()),
          timerTickerProvider.overrideWith(
            (ref) => Stream.value(const Duration(minutes: 20)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(TimerPage)));
  }

  Future<void> openHistorySheet(WidgetTester tester) async {
    await tester.tap(find.byTooltip('타이머 목록'));
    await tester.pumpAndSettle();
  }

  /// 공유 시트에서 [label] 범위를 골라 저장한다
  Future<void> chooseAndSave(WidgetTester tester, String label) async {
    final option = find.widgetWithText(RadioListTile<VisibilityLevel>, label);
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, '저장');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  group('공유 버튼', () {
    final running = makeTimer(id: 'timer-1', status: TimerStatus.running);

    testWidgets('내 타이머와 공유받은 타이머가 섞여 있어도 내 타이머에만 공유 버튼이 있다', (tester) async {
      setSize(tester, const Size(1280, 800));
      final completed = makeTimer(
        id: 'timer-2',
        status: TimerStatus.completed,
      ).copyWith(visibilityLevel: VisibilityLevel.public);
      final shared = makeTimer(
        id: 'shared-1',
        status: TimerStatus.completed,
      ).copyWith(isShared: true, ownerId: 'friend-1');

      await pumpFixed(
        tester,
        active: running,
        history: [running, completed, shared],
      );

      expect(dashboardShare(), findsOneWidget);
      expect(itemShare('timer-1'), findsOneWidget);
      expect(iconOf(tester, itemShare('timer-2')), Icons.public);
      expect(historyItem('shared-1'), findsOneWidget);
      expect(itemShare('shared-1'), findsNothing);
    });

    testWidgets('활성 타이머가 끝나 대기 상태가 되면 대시보드의 공유 버튼이 사라진다', (tester) async {
      repository.listActive = () async => [running];
      final container = await pumpLive(tester, history: () => [running]);
      expect(dashboardShare(), findsOneWidget);

      container
          .read(myActiveTimersProvider.notifier)
          .apply(
            running.copyWith(
              status: TimerStatus.completed,
              updatedAt: running.updatedAt.add(const Duration(minutes: 1)),
            ),
          );
      await tester.pumpAndSettle();

      expect(dashboardShare(), findsNothing);
      expect(dashboardFab(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('휴식을 끝내면 대시보드에 공유 버튼이 돌아온다', (tester) async {
      final paused = makeTimer(
        id: 'timer-1',
        status: TimerStatus.paused,
        allocatedDuration: 25 * 60,
        elapsedTime: 5 * 60,
      ).copyWith(visibilityLevel: VisibilityLevel.friends);
      await pumpFixed(tester, active: paused);

      await tester.tap(dashboardFab(Icons.coffee));
      await tester.pumpAndSettle();
      expect(dashboardShare(), findsNothing);

      await tester.tap(find.byTooltip('휴식 끝내기'));
      await tester.pumpAndSettle();

      expect(dashboardShare(), findsOneWidget);
      expect(iconOf(tester, dashboardShare()), Icons.group_outlined);
    });

    testWidgets('시간이 끝난 내 타이머도 대시보드와 좁은 화면 목록에 공유 버튼이 있고 넘치지 않는다', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      final timeUp = makeTimer(
        id: 'timer-1',
        status: TimerStatus.paused,
        allocatedDuration: 25 * 60,
        elapsedTime: 25 * 60,
      ).copyWith(title: long);

      await pumpFixed(tester, active: timeUp);
      expect(find.text('시간 종료'), findsOneWidget);
      expect(dashboardShare(), findsOneWidget);

      await openHistorySheet(tester);

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('5분 연장'), findsNWidgets(2));
      expect(itemShare('timer-1'), findsOneWidget);
    });

    for (final size in const [
      Size(360, 800),
      Size(360, 560),
      Size(844, 390),
      Size(800, 1280),
      Size(1280, 800),
    ]) {
      testWidgets(
        '${sizeLabel(size)}에서 일시정지 중 할 일 상태와 긴 제목이 있어도 대시보드 공유 버튼이 넘치지 않고 눌린다',
        (tester) async {
          setSize(tester, size);
          final paused = makeTimer(
            id: 'timer-1',
            status: TimerStatus.paused,
            allocatedDuration: 25 * 60,
            elapsedTime: 5 * 60,
          ).copyWith(title: long, todoId: 'todo-1', todo: makeTodo());

          await pumpFixed(tester, active: paused);

          expect(tester.takeException(), isNull);
          final button = dashboardShare();
          expect(button, findsOneWidget);
          final rect = tester.getRect(button);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));

          await tester.tap(button);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(RadioGroup<VisibilityLevel>), findsOneWidget);
          expect(repository.calls, ['visibility:timer-1']);
        },
      );
    }
  });

  group('저장 반영', () {
    final running = makeTimer(id: 'timer-1', status: TimerStatus.running);
    final completed = makeTimer(id: 'timer-2', status: TimerStatus.completed);

    testWidgets('끝난 타이머의 공유 설정을 저장하면 목록을 다시 읽고 대시보드는 대기 상태 그대로다', (
      tester,
    ) async {
      setSize(tester, const Size(1280, 800));
      final friendsOnly = completed.copyWith(
        visibilityLevel: VisibilityLevel.friends,
      );
      var reads = 0;
      repository.getOne = (timerId) async => friendsOnly;
      final container = await pumpLive(
        tester,
        history: () => [if (reads++ == 0) completed else friendsOnly],
      );
      expect(reads, 1);
      expect(dashboardFab(Icons.play_arrow), findsOneWidget);

      await tester.tap(itemShare('timer-2'));
      await tester.pumpAndSettle();
      await chooseAndSave(tester, '친구 공개');

      expect(repository.calls, contains('get:timer-2'));
      expect(reads, 2);
      expect(iconOf(tester, itemShare('timer-2')), Icons.group_outlined);
      expect(dashboardShare(), findsNothing);
      expect(dashboardFab(Icons.play_arrow), findsOneWidget);
      expect(container.read(myActiveTimersProvider).value, isEmpty);
    });

    testWidgets('진행 중인 타이머의 공유 설정을 저장하면 타이머 목록도 다시 읽는다', (tester) async {
      setSize(tester, const Size(1280, 800));
      repository
        ..listActive = (() async => [running])
        ..getOne = (timerId) async =>
            running.copyWith(visibilityLevel: VisibilityLevel.friends);
      var reads = 0;
      final container = await pumpLive(
        tester,
        history: () {
          reads++;
          return [running];
        },
      );
      final before = reads;

      await tester.tap(dashboardShare());
      await tester.pumpAndSettle();
      await chooseAndSave(tester, '친구 공개');

      expect(reads, greaterThan(before));
      expect(iconOf(tester, dashboardShare()), Icons.group_outlined);
      expect(
        container.read(myActiveTimersProvider).value?.single.visibilityLevel,
        VisibilityLevel.friends,
      );
    });

    for (final staleRead in [false, true]) {
      testWidgets(
        '시트를 연 사이 타이머가 끝났으면 저장하고 ${staleRead ? '이전 값을 다시 읽어도' : '다시 읽어도'} 대시보드에 다시 나타나지 않는다',
        (tester) async {
          final done = running.copyWith(
            status: TimerStatus.completed,
            updatedAt: running.updatedAt.add(const Duration(minutes: 1)),
          );
          repository
            ..listActive = (() async => [running])
            ..getOne = (timerId) async => (staleRead ? running : done).copyWith(
              visibilityLevel: VisibilityLevel.friends,
            );
          final container = await pumpLive(tester, history: () => [running]);

          await tester.tap(dashboardShare());
          await tester.pumpAndSettle();
          container.read(myActiveTimersProvider.notifier).apply(done);
          await tester.pumpAndSettle();
          await chooseAndSave(tester, '친구 공개');

          expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
          expect(container.read(myActiveTimersProvider).value, isEmpty);
          expect(dashboardShare(), findsNothing);
          expect(dashboardFab(Icons.play_arrow), findsOneWidget);
        },
      );
    }

    testWidgets('넓은 화면 목록에서 시트를 연 뒤 좁은 화면으로 바뀌어도 저장하고 알린다', (tester) async {
      setSize(tester, const Size(1280, 800));
      final friendsOnly = completed.copyWith(
        visibilityLevel: VisibilityLevel.friends,
      );
      var reads = 0;
      repository
        ..listActive = (() async => [running])
        ..getOne = (timerId) async => friendsOnly;
      await pumpLive(
        tester,
        history: () => [running, if (reads++ == 0) completed else friendsOnly],
      );

      await tester.tap(itemShare('timer-2'));
      await tester.pumpAndSettle();
      setSize(tester, const Size(360, 800));
      await tester.pumpAndSettle();
      expect(find.byType(RadioGroup<VisibilityLevel>), findsOneWidget);

      await chooseAndSave(tester, '친구 공개');

      expect(tester.takeException(), isNull);
      expect(repository.visibilityUpdate?.level, VisibilityLevel.friends);
      expect(find.byType(RadioGroup<VisibilityLevel>), findsNothing);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await openHistorySheet(tester);
      expect(iconOf(tester, itemShare('timer-2')), Icons.group_outlined);
    });

    testWidgets('시트를 연 채 넓은 화면이 좁아져도 고른 값이 남고 그대로 저장한다', (tester) async {
      setSize(tester, const Size(1280, 800));
      await pumpFixed(
        tester,
        active: running,
        friends: () async => [
          makeFriend('friend-1', displayName: '영희'),
          makeFriend('friend-2', displayName: '철수'),
        ],
      );
      repository.getOne = (timerId) async => running;

      await tester.tap(dashboardShare());
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(RadioListTile<VisibilityLevel>, '선택한 친구'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, '철수'));
      await tester.pumpAndSettle();

      setSize(tester, const Size(360, 800));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<RadioGroup<VisibilityLevel>>(
              find.byType(RadioGroup<VisibilityLevel>),
            )
            .groupValue,
        VisibilityLevel.selected,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, '철수'),
            )
            .value,
        isTrue,
      );

      final save = find.widgetWithText(FilledButton, '저장');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(
        repository.visibilityUpdate,
        const VisibilityUpdate(
          level: VisibilityLevel.selected,
          allowedUserIds: ['friend-2'],
        ),
      );
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
    });

    testWidgets('좁은 화면 타이머 목록 시트에서 연 공유 시트는 저장해도 공유 시트만 닫는다', (tester) async {
      setSize(tester, const Size(360, 800));
      repository.getOne = (timerId) async => completed;
      await pumpFixed(tester, active: running, history: [running, completed]);
      await openHistorySheet(tester);

      await tester.tap(itemShare('timer-2'));
      await tester.pumpAndSettle();
      await chooseAndSave(tester, '친구 공개');

      expect(find.byType(RadioGroup<VisibilityLevel>), findsNothing);
      expect(historySheetList(), findsOneWidget);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
    });

    testWidgets('좁은 화면 타이머 목록 시트에서 연 공유 시트를 저장하는 사이 닫아도 목록 시트는 남는다', (
      tester,
    ) async {
      setSize(tester, const Size(360, 800));
      final saved = Completer<void>();
      repository
        ..gate = saved.future
        ..getOne = (timerId) async => completed;
      await pumpFixed(tester, active: running, history: [running, completed]);
      await openHistorySheet(tester);

      await tester.tap(itemShare('timer-2'));
      await tester.pumpAndSettle();
      final option = find.widgetWithText(
        RadioListTile<VisibilityLevel>,
        '친구 공개',
      );
      await tester.tap(option);
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, '저장');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RadioGroup<VisibilityLevel>), findsNothing);
      expect(historySheetList(), findsOneWidget);

      saved.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(historySheetList(), findsOneWidget);
      expect(find.text('공유 설정을 저장했습니다'), findsOneWidget);
    });
  });

  group('친구 타이머', () {
    Finder friendsTab() => find.text('친구 타이머');
    Finder myTab() => find.text('내 타이머');
    Finder sharedItem(String timerId) => find.byWidgetPredicate(
      (widget) => widget is SharedTimerItem && widget.timer.id == timerId,
    );
    Finder inItem(String timerId, Finder finder) =>
        find.descendant(of: sharedItem(timerId), matching: finder);

    /// [ownerId]가 나에게 공유한 타이머
    TimerRead shared(
      String id,
      TimerStatus status, {
      String ownerId = 'friend-1',
      required DateTime startedAt,
      int allocatedDuration = 25 * 60,
      int elapsedTime = 0,
    }) => makeTimer(
      id: id,
      status: status,
      startedAt: startedAt,
      createdAt: startedAt,
      allocatedDuration: allocatedDuration,
      elapsedTime: elapsedTime,
    ).copyWith(isShared: true, ownerId: ownerId);

    final friendsList = [makeFriend('friend-1', displayName: '영희')];

    Future<void> pump(
      WidgetTester tester, {
      Future<List<FriendRead>> Function()? friends,
      Stream<TimerWsTimerEvent> friendActivity = const Stream.empty(),
    }) => pumpFixed(
      tester,
      active: null,
      history: [makeTimer(id: 'mine', status: TimerStatus.completed)],
      friends: friends ?? () async => friendsList,
      friendActivity: friendActivity,
    );

    Future<void> openFriendsTab(WidgetTester tester) async {
      await tester.tap(friendsTab());
      await tester.pumpAndSettle();
    }

    TimerWsTimerEvent event(TimerRead timer) => TimerWsTimerEvent(
      id: 'msg-${timer.id}',
      type: 'timer.updated',
      fromUser: timer.ownerId ?? 'friend-1',
      timestamp: now,
      payload: TimerWsEventPayload(action: 'start', timer: timer),
    );

    testWidgets('할당 시간이 지난 실행 중 공유 타이머는 남은 시간이 00:00:00에서 멈춘다', (tester) async {
      repository.listShared = () async => [
        shared(
          'shared-1',
          TimerStatus.running,
          startedAt: now.subtract(const Duration(minutes: 30)),
        ),
      ];

      await pump(tester);
      await openFriendsTab(tester);
      expect(inItem('shared-1', find.text('00:00:00')), findsOneWidget);
      expect(inItem('shared-1', find.text('진행 중')), findsOneWidget);

      clock = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(inItem('shared-1', find.text('00:00:00')), findsOneWidget);
    });

    testWidgets('친구 목록을 읽지 못해도 공유받은 타이머는 다른 사용자로 보인다', (tester) async {
      repository.listShared = () async => [
        shared('shared-1', TimerStatus.completed, startedAt: now),
      ];

      await pump(tester, friends: () async => throw Exception('네트워크 오류'));
      await openFriendsTab(tester);
      expect(sharedItem('shared-1'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(inItem('shared-1', find.text('다른 사용자')), findsOneWidget);
    });

    for (final recover in ['친구 활동 이벤트', '탭 다시 고르기']) {
      testWidgets('공유받은 타이머를 읽지 못한 뒤 $recover로 다시 읽어 보인다', (tester) async {
        final activity = StreamController<TimerWsTimerEvent>.broadcast();
        addTearDown(activity.close);
        var failing = true;
        final timer = shared('shared-1', TimerStatus.completed, startedAt: now);
        repository.listShared = () async {
          if (failing) throw Exception('네트워크 오류');
          return [timer];
        };

        await pump(tester, friendActivity: activity.stream);
        await tester.tap(friendsTab());
        await tester.pumpAndSettle();
        expect(find.text('공유받은 타이머를 불러올 수 없습니다'), findsOneWidget);

        failing = false;
        if (recover == '친구 활동 이벤트') {
          activity.add(event(timer));
          await tester.pump(sharedTimersRefetchDelay);
          await tester.pumpAndSettle();
        } else {
          await tester.tap(myTab());
          await tester.pumpAndSettle();
          await openFriendsTab(tester);
        }

        expect(find.text('공유받은 타이머를 불러올 수 없습니다'), findsNothing);
        expect(sharedItem('shared-1'), findsOneWidget);
      });
    }

    testWidgets('읽는 동안 탭을 오가도 오류 없이 마지막에 읽은 목록을 보인다', (tester) async {
      final first = Completer<List<TimerRead>>();
      var reads = 0;
      repository.listShared = () {
        reads++;
        if (reads == 1) return first.future;
        return Future.value([
          shared('shared-$reads', TimerStatus.completed, startedAt: now),
        ]);
      };

      await pump(tester);
      await tester.tap(friendsTab());
      await tester.pump();
      await tester.tap(myTab());
      await tester.pump();
      await tester.tap(friendsTab());
      await tester.pumpAndSettle();
      first.complete([shared('stale', TimerStatus.completed, startedAt: now)]);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(sharedItem('stale'), findsNothing);
      expect(sharedItem('shared-$reads'), findsOneWidget);
    });

    testWidgets('친구 활동 이벤트가 연달아 와도 마지막으로 읽은 목록을 보인다', (tester) async {
      final activity = StreamController<TimerWsTimerEvent>.broadcast();
      addTearDown(activity.close);
      var reads = 0;
      repository.listShared = () async {
        reads++;
        return [shared('read-$reads', TimerStatus.completed, startedAt: now)];
      };

      await pump(tester, friendActivity: activity.stream);
      await openFriendsTab(tester);
      final timer = shared('read-1', TimerStatus.running, startedAt: now);
      activity
        ..add(event(timer))
        ..add(event(timer))
        ..add(event(timer));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SharedTimerItem), findsOneWidget);
      expect(sharedItem('read-$reads'), findsOneWidget);
    });

    testWidgets('친구 타이머 탭을 연달아 눌러도 한 번만 읽는다', (tester) async {
      repository.listShared = () async => [
        shared('shared-1', TimerStatus.completed, startedAt: now),
      ];

      await pump(tester);
      await tester.tap(friendsTab());
      await tester.tap(friendsTab());
      await tester.pump();
      await tester.tap(friendsTab());
      await tester.pumpAndSettle();

      expect(repository.calls, ['listShared']);
      expect(sharedItem('shared-1'), findsOneWidget);
    });

    testWidgets('친구 타이머를 보지 않을 때 온 친구 활동 이벤트로는 읽지 않고, 고르면 읽는다', (tester) async {
      final activity = StreamController<TimerWsTimerEvent>.broadcast();
      addTearDown(activity.close);
      final timer = shared('shared-1', TimerStatus.running, startedAt: now);
      repository.listShared = () async => [timer];

      await pump(tester, friendActivity: activity.stream);
      activity.add(event(timer));
      await tester.pumpAndSettle();
      expect(repository.calls, isEmpty);

      await openFriendsTab(tester);

      expect(repository.calls, ['listShared']);
      expect(sharedItem('shared-1'), findsOneWidget);
    });

    testWidgets('친구 목록이 공유받은 타이머보다 늦게 오면 그때 주인 이름을 보인다', (tester) async {
      final loaded = Completer<List<FriendRead>>();
      repository.listShared = () async => [
        shared('shared-1', TimerStatus.completed, startedAt: now),
      ];

      await pump(tester, friends: () => loaded.future);
      await openFriendsTab(tester);
      expect(inItem('shared-1', find.text('다른 사용자')), findsOneWidget);

      loaded.complete(friendsList);
      await tester.pumpAndSettle();

      expect(inItem('shared-1', find.text('영희')), findsOneWidget);
    });

    testWidgets('내 타이머 목록을 읽지 못해도 친구 타이머는 보인다', (tester) async {
      repository.listShared = () async => [
        shared('shared-1', TimerStatus.completed, startedAt: now),
      ];

      await pumpFixed(
        tester,
        active: null,
        historyError: Exception('네트워크 오류'),
        friends: () async => friendsList,
      );
      await tester.pumpAndSettle();
      expect(find.text('히스토리를 불러올 수 없습니다'), findsOneWidget);

      await openFriendsTab(tester);

      expect(find.text('히스토리를 불러올 수 없습니다'), findsNothing);
      expect(sharedItem('shared-1'), findsOneWidget);
      expect(inItem('shared-1', find.text('영희')), findsOneWidget);
    });

    testWidgets('공유받은 항목을 눌러도 아무것도 열거나 보내지 않는다', (tester) async {
      setSize(tester, const Size(1280, 800));
      repository.listShared = () async => [
        shared('shared-1', TimerStatus.running, startedAt: now),
      ];

      await pump(tester);
      await openFriendsTab(tester);
      await tester.tap(sharedItem('shared-1'));
      await tester.pumpAndSettle();

      expect(sheet(), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(repository.calls, ['listShared']);
    });

    testWidgets('넓은 화면끼리 창 크기가 바뀌어도 친구 타이머 탭이 남는다', (tester) async {
      setSize(tester, const Size(1280, 800));
      repository.listShared = () async => [
        shared('shared-1', TimerStatus.completed, startedAt: now),
      ];

      await pump(tester);
      await openFriendsTab(tester);
      expect(sharedItem('shared-1'), findsOneWidget);

      for (final size in const [Size(800, 1280), Size(844, 390)]) {
        setSize(tester, size);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: sizeLabel(size));
        expect(sharedItem('shared-1'), findsOneWidget, reason: sizeLabel(size));
        expect(historyItem('mine'), findsNothing, reason: sizeLabel(size));
      }
    });

    // 탭은 목록마다 따로 고른다. 좁은 화면의 목록 시트는 열 때마다 새 목록이다
    testWidgets('넓은 화면에서 친구 타이머를 골랐어도 좁은 화면의 목록 시트는 내 타이머부터 보인다', (
      tester,
    ) async {
      setSize(tester, const Size(1280, 800));
      repository.listShared = () async => [
        shared('shared-1', TimerStatus.completed, startedAt: now),
      ];

      await pump(tester);
      await openFriendsTab(tester);
      setSize(tester, const Size(360, 800));
      await tester.pumpAndSettle();
      await openHistorySheet(tester);

      expect(historyItem('mine'), findsOneWidget);
      expect(find.byType(SharedTimerItem), findsNothing);

      await openFriendsTab(tester);

      expect(sharedItem('shared-1'), findsOneWidget);
    });

    for (final size in const [
      Size(360, 800),
      Size(360, 560),
      Size(844, 390),
      Size(800, 1280),
      Size(1280, 800),
    ]) {
      testWidgets('${sizeLabel(size)}에서 긴 이름의 친구 타이머 목록도 넘치지 않고 끝까지 굴린다', (
        tester,
      ) async {
        setSize(tester, size);
        repository.listShared = () async => [
          for (var i = 0; i < 12; i++)
            shared(
              'shared-$i',
              const [
                TimerStatus.running,
                TimerStatus.paused,
                TimerStatus.completed,
                TimerStatus.cancelled,
              ][i % 4],
              startedAt: now.subtract(Duration(minutes: i)),
              elapsedTime: 10 * 60,
            ).copyWith(title: '$long $i'),
        ];

        await pump(
          tester,
          friends: () async => [
            makeFriend(
              'friend-1',
              displayName: '이름이 아주 아주 아주 길어서 한 줄에 다 들어가지 않는 친구',
            ),
          ],
        );
        if (size.width < 600) await openHistorySheet(tester);
        await openFriendsTab(tester);

        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          sharedItem('shared-11'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(TimerHistoryList),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(sharedItem('shared-11'), findsOneWidget);
      });

      testWidgets('${sizeLabel(size)}에서 공유받은 타이머가 없다는 안내가 넘치지 않는다', (
        tester,
      ) async {
        setSize(tester, size);

        await pump(tester);
        if (size.width < 600) await openHistorySheet(tester);
        await openFriendsTab(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('공유받은 타이머가 없습니다'), findsOneWidget);
      });

      testWidgets('${sizeLabel(size)}에서 공유받은 타이머를 읽지 못한 긴 오류도 넘치지 않는다', (
        tester,
      ) async {
        setSize(tester, size);
        // 서버 오류 응답의 DioException 문구 길이
        repository.listShared = () async => throw Exception(
          'DioException [bad response]: This exception was thrown because '
          'the response has a status code of 500 and '
          'RequestOptions.validateStatus was configured to throw for this '
          'status code.\nThe status code of 500 has the following meaning: '
          '"Server error - the server failed to fulfil an apparent request"\n'
          'Read more about status codes at '
          'https://developer.mozilla.org/en-US/docs/Web/HTTP/Status\n'
          'In order to resolve this exception you typically have either to '
          'verify and fix your request code or you have to fix the server '
          'code.',
        );

        await pump(tester);
        if (size.width < 600) await openHistorySheet(tester);
        await tester.tap(friendsTab());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('공유받은 타이머를 불러올 수 없습니다'), findsOneWidget);
      });
    }
  });
}
