import 'dart:async';

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

  TimerWsTimerEvent event() => TimerWsTimerEvent(
    id: 'msg-1',
    type: 'timer.updated',
    fromUser: 'friend-1',
    timestamp: DateTime.utc(2026, 11, 9),
    payload: TimerWsEventPayload(action: 'start', timer: shared('any')),
  );

  test('처음 읽는 중에 친구 활동 이벤트가 오면 나중에 읽은 목록으로 끝난다', () async {
    final first = Completer<List<TimerRead>>();
    var reads = 0;
    repository.listShared = () {
      reads++;
      return reads == 1 ? first.future : Future.value([shared('fresh')]);
    };
    container.listen(sharedTimersProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    activity.add(event());
    await Future<void>.delayed(Duration.zero);
    first.complete([shared('stale')]);
    final timers = await container.read(sharedTimersProvider.future);

    expect(reads, 2);
    expect(timers.map((timer) => timer.id), ['fresh']);
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
