import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  final clock = DateTime.utc(2026, 11, 9, 10, 10);

  // 10:00에 시작해 실행 중인 A와 10:05에 시작해 일시정지한 B. 가장 최근에 시작한 타이머는 B다
  final runningA = makeTimer(
    id: 'a',
    status: TimerStatus.running,
    startedAt: DateTime.utc(2026, 11, 9, 10),
    allocatedDuration: 25 * 60,
  );
  final pausedB = makeTimer(
    id: 'b',
    status: TimerStatus.paused,
    startedAt: DateTime.utc(2026, 11, 9, 10, 5),
    allocatedDuration: 25 * 60,
    elapsedTime: 60,
  );

  group('focusedTimer', () {
    test('고르지 않았으면 더 나중에 시작한 일시정지 타이머보다 실행 중인 타이머다', () {
      expect(focusedTimer([pausedB, runningA], null)?.id, 'a');
    });

    test('실행 중인 타이머가 여럿이면 가장 최근에 시작한 것이다', () {
      final runningB = pausedB.copyWith(status: TimerStatus.running);
      expect(focusedTimer([runningB, runningA], null)?.id, 'b');
    });

    test('실행 중인 타이머가 없으면 가장 최근에 시작한 타이머다', () {
      final pausedA = runningA.copyWith(status: TimerStatus.paused);
      expect(focusedTimer([pausedB, pausedA], null)?.id, 'b');
    });

    test('고른 타이머가 있으면 그것이다', () {
      expect(focusedTimer([pausedB, runningA], 'b')?.id, 'b');
    });

    test('고른 타이머가 목록에 없으면(끝났으면) 기본 타이머다', () {
      expect(focusedTimer([pausedB, runningA], 'gone')?.id, 'a');
    });

    test('활성 타이머가 없으면 null이다', () {
      expect(focusedTimer(const [], 'a'), isNull);
      expect(focusedTimer(const [], null), isNull);
    });
  });

  group('activeTimerProvider', () {
    late FakeTimerRepository repository;

    Future<ProviderContainer> boot(List<TimerRead> active) async {
      repository = FakeTimerRepository()..listActive = () async => active;
      final container = ProviderContainer(
        overrides: [
          timerRepositoryProvider.overrideWithValue(repository),
          timerWsClientProvider.overrideWithValue(null),
          currentUserProvider.overrideWithValue(null),
          timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => clock),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(activeTimerProvider, (_, _) {});
      container.listen(timerControllerProvider, (_, _) {});
      await container.read(myActiveTimersProvider.future);
      return container;
    }

    String? activeId(ProviderContainer container) =>
        container.read(activeTimerProvider).value?.id;

    void focus(ProviderContainer container, String? id) =>
        container.read(focusedTimerIdProvider.notifier).focus(id);

    TimerController controller(ProviderContainer container) =>
        container.read(timerControllerProvider.notifier);

    test('고른 타이머를 따르고 고른 것을 풀면 기본 타이머로 돌아간다', () async {
      final container = await boot([runningA, pausedB]);
      expect(activeId(container), 'a');

      focus(container, 'b');
      expect(activeId(container), 'b');

      focus(container, null);
      expect(activeId(container), 'a');
    });

    test('고른 타이머가 끝나 활성 목록에서 빠지면 기본 타이머로 돌아간다', () async {
      final container = await boot([runningA, pausedB]);
      focus(container, 'b');

      container
          .read(myActiveTimersProvider.notifier)
          .apply(
            pausedB.copyWith(status: TimerStatus.completed, updatedAt: clock),
          );

      expect(activeId(container), 'a');
    });

    test('id 없는 재개·정지·연장은 고른 타이머에 보낸다', () async {
      final expiredB = pausedB.copyWith(elapsedTime: 25 * 60);
      final container = await boot([runningA, expiredB]);
      focus(container, 'b');
      repository.respond = (timerId, status) =>
          expiredB.copyWith(status: status, updatedAt: clock);

      await controller(container).extendTimer(by: const Duration(minutes: 5));
      await controller(container).stopTimer();

      expect(repository.calls, ['list', 'update:b', 'resume:b', 'stop:b']);
      expect(repository.updated?.allocatedDuration, 30 * 60);
    });

    test('id 없는 일시정지는 고른 실행 중 타이머에 보낸다', () async {
      final runningB = pausedB.copyWith(status: TimerStatus.running);
      final container = await boot([runningA, runningB]);
      focus(container, 'a');

      await controller(container).pauseTimer();

      expect(repository.calls, ['list', 'pause:a']);
    });

    test('id 없는 재개는 고른 일시정지 타이머가 실행 중이 아니면 보내지 않는다', () async {
      final container = await boot([runningA, pausedB]);
      focus(container, 'a');

      await expectLater(controller(container).resumeTimer(), throwsException);

      expect(repository.calls, ['list']);
    });

    test('여러 할 일로 시작하면 시작한 타이머를 모두 반영하고 마지막으로 시작한 타이머를 보인다', () async {
      final container = await boot([runningA, pausedB]);
      focus(container, 'b');
      repository.createResponse = (data) {
        if (data.todoId == 'todo-2') throw Exception('서버 오류');
        return makeTimer(
          id: 'timer-${data.todoId}',
          status: TimerStatus.running,
          startedAt: clock,
        ).copyWith(todoId: data.todoId, updatedAt: clock);
      };

      final failed = await controller(container).startTimers(
        todos: [
          makeTodo(id: 'todo-1'),
          makeTodo(id: 'todo-2'),
          makeTodo(id: 'todo-3'),
        ],
        duration: const Duration(minutes: 25),
      );

      expect(failed.map((todo) => todo.id), ['todo-2']);
      final ids = container
          .read(myActiveTimersProvider)
          .value!
          .map((timer) => timer.id);
      expect(ids, containsAll(['a', 'b', 'timer-todo-1', 'timer-todo-3']));
      expect(ids, isNot(contains('timer-todo-2')));
      expect(activeId(container), 'timer-todo-3');
    });

    test('새 타이머를 시작하면 고른 타이머 대신 시작한 타이머를 보인다', () async {
      final container = await boot([runningA, pausedB]);
      focus(container, 'b');
      repository.respond = (timerId, status) => makeTimer(
        id: 'c',
        status: status,
        startedAt: clock,
      ).copyWith(updatedAt: clock);

      await controller(container).startTimer(title: 'C');

      expect(container.read(focusedTimerIdProvider), 'c');
      expect(activeId(container), 'c');
    });
  });
}
