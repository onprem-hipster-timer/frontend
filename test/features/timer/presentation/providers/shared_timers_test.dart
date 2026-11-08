import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  group('sharedTimersProvider', () {
    late FakeTimerRepository repository;
    late StreamController<TimerWsTimerEvent> activity;
    late ProviderContainer container;

    setUp(() {
      repository = FakeTimerRepository();
      activity = StreamController<TimerWsTimerEvent>.broadcast();
      container = ProviderContainer(
        overrides: [
          timerRepositoryProvider.overrideWithValue(repository),
          timerFriendActivityProvider.overrideWith((ref) => activity.stream),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      activity.close();
    });

    /// 목록을 보는 화면처럼 지켜보며 처음 읽은 값을 기다린다
    Future<List<TimerRead>> watch() {
      container.listen(sharedTimersProvider, (_, _) {});
      return container.read(sharedTimersProvider.future);
    }

    TimerRead shared(String id, {DateTime? startedAt, DateTime? createdAt}) =>
        makeTimer(
          id: id,
          status: TimerStatus.completed,
          startedAt: startedAt,
          createdAt: createdAt,
        ).copyWith(isShared: true, ownerId: 'friend-1');

    test('공유받은 타이머를 최근에 시작한 순으로 읽는다', () async {
      repository.listShared = () async => [
        shared('old', startedAt: DateTime.utc(2026, 11, 1)),
        shared('newest', startedAt: DateTime.utc(2026, 11, 3)),
        // 시작 시각이 없으면 만든 시각으로 센다
        shared('not-started', createdAt: DateTime.utc(2026, 11, 2)),
      ];

      final timers = await watch();

      expect(timers.map((timer) => timer.id), ['newest', 'not-started', 'old']);
      expect(repository.calls, ['listShared']);
    });

    test('친구의 타이머 이벤트가 오면 다시 읽는다', () async {
      var reads = 0;
      repository.listShared = () async {
        reads++;
        return [shared('read-$reads')];
      };
      await watch();

      activity.add(
        TimerWsTimerEvent(
          id: 'msg-1',
          type: 'timer.updated',
          fromUser: 'friend-1',
          timestamp: DateTime.utc(2026, 11, 9),
          payload: TimerWsEventPayload(
            action: 'start',
            timer: shared('read-1'),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final timers = await container.read(sharedTimersProvider.future);

      expect(reads, 2);
      expect(timers.single.id, 'read-2');
    });
  });

  testWidgets('serverNowProvider는 서버 기준 시각을 바로 한 번, 이후 1초마다 낸다', (
    tester,
  ) async {
    var device = DateTime.utc(2026, 11, 9, 10);
    final container = ProviderContainer(
      overrides: [
        serverClockProvider.overrideWithValue(
          ServerClock(deviceNow: () => device),
        ),
      ],
    );
    final seen = <DateTime>[];
    container.listen(serverNowProvider, (_, next) {
      if (next case AsyncData(:final value)) seen.add(value);
    });

    await tester.pump();
    expect(seen, [DateTime.utc(2026, 11, 9, 10)]);

    device = device.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(seen, [
      DateTime.utc(2026, 11, 9, 10),
      DateTime.utc(2026, 11, 9, 10, 0, 1),
    ]);

    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
