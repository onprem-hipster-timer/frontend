import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

/// sharedTimersProvider의 경계. 기본 동작은 shared_timers_test.dart
void main() {
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

  TimerRead shared(String id, {DateTime? startedAt, DateTime? createdAt}) =>
      makeTimer(
        id: id,
        status: TimerStatus.completed,
        startedAt: startedAt,
        createdAt: createdAt,
      ).copyWith(isShared: true, ownerId: 'friend-1');

  TimerWsTimerEvent event([String action = 'start']) => TimerWsTimerEvent(
    id: 'msg-$action',
    type: 'timer.updated',
    fromUser: 'friend-1',
    timestamp: DateTime.utc(2026, 11, 9),
    payload: TimerWsEventPayload(action: action, timer: shared('any')),
  );

  int lists() => repository.calls.where((call) => call == 'listShared').length;

  group('친구 이벤트가 몰려 올 때', () {
    test('창 안에 온 expire·update·resume은 마지막 이벤트 뒤 한 번만 다시 읽는다', () {
      fakeAsync((async) {
        container.listen(sharedTimersProvider, (_, _) {});
        async.flushMicrotasks();
        expect(lists(), 1);

        activity.add(event('expire'));
        async.elapse(const Duration(milliseconds: 200));
        activity.add(event('update'));
        async.elapse(const Duration(milliseconds: 200));
        activity.add(event('resume'));
        async.elapse(
          sharedTimersRefetchDelay - const Duration(milliseconds: 1),
        );
        expect(lists(), 1);

        async.elapse(const Duration(milliseconds: 1));
        expect(lists(), 2);

        async.elapse(const Duration(seconds: 5));
        expect(lists(), 2);
      });
    });

    test('창보다 띄어 온 이벤트는 저마다 다시 읽는다', () {
      fakeAsync((async) {
        container.listen(sharedTimersProvider, (_, _) {});
        async.flushMicrotasks();

        for (final action in ['expire', 'update', 'resume']) {
          activity.add(event(action));
          async.elapse(sharedTimersRefetchDelay);
        }

        expect(lists(), 4);
      });
    });

    test('다시 읽기 전에 버리면 다시 읽지 않고 오류도 없다', () {
      fakeAsync((async) {
        final local = ProviderContainer(
          overrides: [
            timerRepositoryProvider.overrideWithValue(repository),
            timerFriendActivityProvider.overrideWith((ref) => activity.stream),
          ],
        );
        local.listen(sharedTimersProvider, (_, _) {});
        async.flushMicrotasks();

        activity.add(event());
        async.flushMicrotasks();
        local.dispose();
        async.elapse(sharedTimersRefetchDelay * 2);

        expect(lists(), 1);
        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  test('처음 읽는 중에 친구 활동 이벤트가 오면 나중에 읽은 목록으로 끝난다', () {
    fakeAsync((async) {
      final first = Completer<List<TimerRead>>();
      var reads = 0;
      repository.listShared = () {
        reads++;
        return reads == 1 ? first.future : Future.value([shared('fresh')]);
      };
      container.listen(sharedTimersProvider, (_, _) {});
      async.flushMicrotasks();

      activity.add(event());
      async.flushMicrotasks();
      first.complete([shared('stale')]);
      async.elapse(sharedTimersRefetchDelay);

      expect(reads, 2);
      expect(
        container.read(sharedTimersProvider).value?.map((timer) => timer.id),
        ['fresh'],
      );
    });
  });

  test('시작 시각이 없는 타이머끼리는 만든 시각으로, 시작한 타이머와 섞여도 최근 순이다', () async {
    repository.listShared = () async => [
      shared('created-old', createdAt: DateTime.utc(2026, 10, 1)),
      shared('started-mid', startedAt: DateTime.utc(2026, 10, 15)),
      shared('created-new', createdAt: DateTime.utc(2026, 11, 1)),
    ];
    container.listen(sharedTimersProvider, (_, _) {});

    final timers = await container.read(sharedTimersProvider.future);

    expect(timers.map((timer) => timer.id), [
      'created-new',
      'started-mid',
      'created-old',
    ]);
  });

  test('목록이 비면 빈 목록이다', () async {
    container.listen(sharedTimersProvider, (_, _) {});

    expect(await container.read(sharedTimersProvider.future), isEmpty);
    expect(repository.calls, ['listShared']);
  });
}
