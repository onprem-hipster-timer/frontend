import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/pages/timer_page.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';
import '../../../../helpers/timer_gallery_finders.dart';

/// 실제 1초 틱([timerTickerProvider])으로 센 대시보드 시계가 화면 변화에도 서버 기준 진행을 잃지 않는지
void main() {
  // 10:00에 시작해 실행 중인 A(10:10에 15분 남음)와 5분 쓰고 일시정지한 B(20분 남음)
  final runningA = makeTimer(
    id: 'a',
    status: TimerStatus.running,
    startedAt: DateTime.utc(2026, 11, 9, 10),
    createdAt: DateTime.utc(2026, 11, 9, 9, 30),
    allocatedDuration: 25 * 60,
  ).copyWith(title: 'A 작업');
  final pausedB = makeTimer(
    id: 'b',
    status: TimerStatus.paused,
    startedAt: DateTime.utc(2026, 11, 9, 10, 5),
    createdAt: DateTime.utc(2026, 11, 9, 9),
    allocatedDuration: 25 * 60,
    elapsedTime: 5 * 60,
  ).copyWith(title: 'B 작업');

  /// 서버 기준 지금
  late DateTime now;
  late FakeTimerRepository repository;

  setUp(() {
    now = DateTime.utc(2026, 11, 9, 10, 10);
    repository = FakeTimerRepository()
      ..listActive = () async => [runningA, pausedB];
  });

  /// 서버 시각을 [seconds]초 옮기며 1초씩 흘린다
  Future<void> tick(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Widget app(
    Widget home, {
    ServerClock? clock,
    List<TimerRead> history = const [],
  }) => ProviderScope(
    overrides: [
      allTodosProvider.overrideWith((ref) async => const <TodoRead>[]),
      timerFriendActivityProvider.overrideWith(
        (ref) => const Stream<TimerWsTimerEvent>.empty(),
      ),
      timerRepositoryProvider.overrideWithValue(repository),
      timerWsClientProvider.overrideWithValue(null),
      currentUserProvider.overrideWithValue(null),
      serverClockProvider.overrideWithValue(
        clock ?? ServerClock(deviceNow: () => now),
      ),
      timerHistoryProvider.overrideWith((ref) async => history),
    ],
    child: MaterialApp(home: home),
  );

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }

  String? clockText(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byType(DigitalClock),
          matching: find.byType(Text),
        ),
      )
      .data;

  /// 화면을 내려 1초 틱을 멈춘다
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  /// 갤러리를 넘겨 [id] 타이머를 고른다. 쪽은 최근에 시작한 B, A 순서다
  Future<void> swipeTo(WidgetTester tester, String id) async {
    await swipeTimerGallery(tester, forward: id == 'a');
    expect(shownTimerPage(tester), id);
  }

  testWidgets('타이머를 오가며 골라도 어느 쪽의 진행도 처음으로 돌아가지 않는다', (tester) async {
    setSize(tester, const Size(1200, 900));
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const TimerPage()));
    await tester.pump();
    expect(clockText(tester), '00:15:00');

    await tick(tester, 3);
    expect(clockText(tester), '00:14:57');

    await swipeTo(tester, 'b');
    expect(clockText(tester), '00:20:00');
    await tick(tester, 2);
    expect(clockText(tester), '00:20:00');

    // 다시 고른 순간부터 그동안 흐른 시간을 반영한다
    await swipeTo(tester, 'a');
    expect(clockText(tester), '00:14:55');
    await tick(tester, 1);
    expect(clockText(tester), '00:14:54');

    await unmount(tester);
  });

  testWidgets('같은 타이머의 새 응답으로 틱이 다시 시작돼도 시계가 이어진다', (tester) async {
    setSize(tester, const Size(1200, 900));
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const TimerPage()));
    await tester.pump();
    await tick(tester, 5);
    expect(clockText(tester), '00:14:55');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TimerPage)),
    );
    container
        .read(myActiveTimersProvider.notifier)
        .apply(runningA.copyWith(updatedAt: now));
    await tester.pump();

    expect(clockText(tester), '00:14:55');
    await tick(tester, 1);
    expect(clockText(tester), '00:14:54');

    await unmount(tester);
  });

  testWidgets('넓은 화면과 좁은 화면을 오가도 시계가 이어진다', (tester) async {
    setSize(tester, const Size(1200, 900));
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const TimerPage()));
    await tester.pump();
    await tick(tester, 2);
    expect(clockText(tester), '00:14:58');

    setSize(tester, const Size(400, 900));
    await tester.pump();
    expect(clockText(tester), '00:14:58');
    await tick(tester, 1);
    expect(clockText(tester), '00:14:57');

    setSize(tester, const Size(1200, 900));
    await tester.pump();
    expect(clockText(tester), '00:14:57');

    await unmount(tester);
  });

  testWidgets('다른 탭에 있다 돌아오면 그동안 흐른 시간을 바로 보인다', (tester) async {
    setSize(tester, const Size(1200, 900));
    addTearDown(tester.view.reset);
    final tab = ValueNotifier(0);
    addTearDown(tab.dispose);
    await tester.pumpWidget(
      app(
        ValueListenableBuilder<int>(
          valueListenable: tab,
          builder: (context, index, _) => IndexedStack(
            index: index,
            children: [
              TickerMode(enabled: index == 0, child: const TimerPage()),
              TickerMode(enabled: index == 1, child: const Text('다른 탭')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(clockText(tester), '00:15:00');

    tab.value = 1;
    await tester.pump();
    await tick(tester, 60);

    tab.value = 0;
    await tester.pump();
    expect(clockText(tester), '00:14:00');

    await unmount(tester);
  });

  testWidgets('기기 시계가 앞서 있어도 서버 시각으로 세어 시간 종료로 보이지 않는다', (tester) async {
    setSize(tester, const Size(1200, 900));
    addTearDown(tester.view.reset);
    // 기기 시계가 서버보다 30분 빠르다
    final clock = ServerClock(
      deviceNow: () => now.add(const Duration(minutes: 30)),
    );
    final sent = now.add(const Duration(minutes: 30));
    clock.addSample(
      serverDate: now.subtract(const Duration(milliseconds: 500)),
      sentAt: sent,
      receivedAt: sent,
    );
    await tester.pumpWidget(app(const TimerPage(), clock: clock));
    await tester.pump();

    expect(clockText(tester), '00:15:00');
    expect(find.text('시간 종료'), findsNothing);
    await tick(tester, 1);
    expect(clockText(tester), '00:14:59');

    await unmount(tester);
  });

  testWidgets('넓은 화면과 목록 시트가 같은 휴식을 보이고, 시트에서 재개하면 휴식이 끝난다', (tester) async {
    setSize(tester, const Size(1200, 900));
    addTearDown(tester.view.reset);
    repository.listActive = () async => [pausedB];
    repository.respond = (id, status) =>
        pausedB.copyWith(status: status, startedAt: now, updatedAt: now);
    await tester.pumpWidget(app(const TimerPage(), history: [pausedB]));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TimerPage)),
    );
    container
        .read(breakTimerProvider.notifier)
        .start(const Duration(minutes: 5));
    await tester.pump();
    await tick(tester, 2);
    expect(find.text('휴식'), findsOneWidget);
    expect(clockText(tester), '00:04:58');

    // 좁은 화면으로 바꿔 목록을 시트로 연다
    setSize(tester, const Size(400, 900));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.byType(TimerDashboard), findsOneWidget);
    expect(clockText(tester), '00:04:58');

    await tester.tap(
      find.descendant(
        of: find.byType(TimerHistoryItem),
        matching: find.byIcon(Icons.play_arrow),
      ),
    );
    await tester.pump();

    expect(container.read(breakTimerProvider), isNull);
    expect(find.text('휴식'), findsNothing);
    expect(clockText(tester), '00:20:00');

    await unmount(tester);
  });
}
