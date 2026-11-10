import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

class _FakeWsClient extends Fake implements TimerWsClient {
  @override
  Stream<TimerWsEvent> get messageStream => const Stream.empty();
}

final _startedAt = DateTime.utc(2026, 11, 6, 10);
final _now = DateTime.utc(2026, 11, 6, 10, 5);
final _updatedAt = DateTime.utc(2026, 11, 6, 10, 1);

TimerRead _held(TimerStatus status, {int elapsed = 30}) => makeTimer(
  id: 't1',
  status: status,
  startedAt: _startedAt,
  elapsedTime: elapsed,
).copyWith(updatedAt: _updatedAt);

void main() {
  late FakeTimerRepository repository;
  late Completer<void> gate;

  setUp(() {
    repository = FakeTimerRepository();
    gate = Completer<void>();
    repository.gate = gate.future;
    repository.respond = (id, status) => makeTimer(
      id: id,
      status: status,
      startedAt: _startedAt,
    ).copyWith(updatedAt: DateTime.utc(2026, 11, 6, 10, 9));
  });

  Future<ProviderContainer> boot(TimerRead held) async {
    repository.listActive = () async => [held];
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        timerWsClientProvider.overrideWithValue(_FakeWsClient()),
        currentUserProvider.overrideWithValue(
          AuthUser(
            id: 'me',
            email: 'me@example.com',
            emailVerified: true,
            createdAt: DateTime.utc(2026),
          ),
        ),
        timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
        serverClockProvider.overrideWithValue(
          ServerClock(deviceNow: () => _now),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(myActiveTimersProvider, (_, _) {});
    container.listen(timerControllerProvider, (_, _) {});
    await container.read(myActiveTimersProvider.future);
    return container;
  }

  TimerRead shownActive(ProviderContainer c) =>
      c.read(myActiveTimersProvider).requireValue.single;

  TimerController controller(ProviderContainer c) =>
      c.read(timerControllerProvider.notifier);

  test('일시정지는 응답 전에 서버 시각 기준 경과 시간으로 멈춘 타이머를 보인다', () async {
    final c = await boot(_held(TimerStatus.running));

    final sent = controller(c).pauseTimer(timerId: 't1');
    await pumpEventQueue();

    final shown = shownActive(c);
    expect(shown.status, TimerStatus.paused);
    expect(shown.elapsedTime, 30 + 5 * 60);
    expect(c.read(timerViewsProvider)['t1']?.status, TimerStatus.paused);
    expect(c.read(timerControllerProvider).isLoading, isFalse);

    gate.complete();
    await sent;
    expect(shownActive(c).updatedAt, DateTime.utc(2026, 11, 6, 10, 9));
    expect(
      c.read(timerViewsProvider)['t1']?.updatedAt,
      DateTime.utc(2026, 11, 6, 10, 9),
    );
  });

  test('재개는 응답 전에 지금부터 다시 세는 타이머를 보인다', () async {
    final c = await boot(_held(TimerStatus.paused));

    final sent = controller(c).resumeTimer(timerId: 't1');
    await pumpEventQueue();

    final shown = shownActive(c);
    expect(shown.status, TimerStatus.running);
    expect(shown.startedAt, _now);
    expect(shown.elapsedTime, 30);

    gate.complete();
    await sent;
  });

  test('실패하면 원래 타이머로 되돌리고 예외를 던진다', () async {
    final held = _held(TimerStatus.running);
    final c = await boot(held);
    repository.error = Exception('400');

    final sent = controller(c).pauseTimer(timerId: 't1');
    await pumpEventQueue();
    expect(shownActive(c).status, TimerStatus.paused);

    gate.complete();
    await expectLater(sent, throwsA(same(repository.error)));
    expect(shownActive(c), held);
    expect(c.read(timerViewsProvider), isNot(contains('t1')));
    expect(c.read(timerControllerProvider).hasError, isTrue);
  });

  test('응답을 기다리는 타이머에 또 일시정지·재개하면 보내지 않고, 완료는 그 응답 뒤에 보낸다', () async {
    final c = await boot(_held(TimerStatus.running));

    final first = controller(c).pauseTimer(timerId: 't1');
    await pumpEventQueue();
    await controller(c).resumeTimer(timerId: 't1');
    await controller(c).pauseTimer(timerId: 't1');
    final stop = controller(c).stopTimer(timerId: 't1');
    await pumpEventQueue();
    expect(repository.calls.where((call) => call != 'list'), ['pause:t1']);

    gate.complete();
    await first;
    await stop;
    expect(repository.calls.where((call) => call != 'list'), [
      'pause:t1',
      'stop:t1',
    ]);
  });

  test('응답 뒤에는 같은 타이머에 다시 명령할 수 있다', () async {
    final c = await boot(_held(TimerStatus.running));
    gate.complete();

    await controller(c).pauseTimer(timerId: 't1');
    await controller(c).resumeTimer(timerId: 't1');

    expect(repository.calls.where((call) => call != 'list'), [
      'pause:t1',
      'resume:t1',
    ]);
  });

  test('완료는 응답 전에는 타이머를 바꾸지 않고 로딩도 쓰지 않는다', () async {
    final held = _held(TimerStatus.running);
    final c = await boot(held);

    final sent = controller(c).stopTimer(timerId: 't1');
    await pumpEventQueue();

    expect(shownActive(c), held);
    expect(c.read(timerControllerProvider).isLoading, isFalse);

    gate.complete();
    await sent;
    expect(c.read(myActiveTimersProvider).requireValue, isEmpty);
  });

  test('가진 적 없는 타이머는 먼저 보이지 않고 명령만 보낸다', () async {
    final c = await boot(_held(TimerStatus.running));

    final sent = controller(c).pauseTimer(timerId: 'other');
    await pumpEventQueue();

    expect(shownActive(c).status, TimerStatus.running);
    expect(c.read(timerViewsProvider), isNot(contains('other')));

    gate.complete();
    await sent;
    expect(repository.calls, contains('pause:other'));
  });
}
