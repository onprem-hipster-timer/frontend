import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  late FakeTimerRepository repository;

  setUp(() => repository = FakeTimerRepository());

  ProviderContainer boot({TimerRead? active}) {
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        activeTimerProvider.overrideWithValue(AsyncData(active)),
        timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
      ],
    );
    addTearDown(container.dispose);
    container.listen(activeTimerProvider, (_, _) {});
    container.listen(timerControllerProvider, (_, _) {});
    return container;
  }

  TimerController controller(ProviderContainer container) =>
      container.read(timerControllerProvider.notifier);

  test('시작은 POST /v1/timers로 보내고 제목·할당 시간 기본값을 채운다', () async {
    final container = boot();

    await controller(container).startTimer(relatedTodoId: 'todo-1');

    expect(repository.calls, ['create']);
    expect(repository.created?.todoId, 'todo-1');
    expect(repository.created?.title, '새 작업');
    expect(repository.created?.allocatedDuration, 25 * 60);
  });

  test('id를 주면 그 타이머를 일시정지·재개·정지한다', () async {
    final container = boot();

    await controller(container).pauseTimer(timerId: 't1');
    await controller(container).resumeTimer(timerId: 't1');
    await controller(container).stopTimer(timerId: 't1');

    expect(repository.calls, ['pause:t1', 'resume:t1', 'stop:t1']);
  });

  test('id를 생략하면 활성 타이머에 명령한다', () async {
    final container = boot(
      active: makeTimer(id: 'active-1', status: TimerStatus.running),
    );

    await controller(container).pauseTimer();

    expect(repository.calls, ['pause:active-1']);
  });

  test('REST가 실패하면 예외를 그대로 던지고 상태를 에러로 둔다', () async {
    final container = boot();
    repository.error = Exception('400');

    await expectLater(
      controller(container).pauseTimer(timerId: 't1'),
      throwsA(same(repository.error)),
    );
    expect(container.read(timerControllerProvider).hasError, isTrue);
  });

  test('연장은 allocated_duration을 늘려 PATCH한 뒤 재개한다', () async {
    final container = boot(
      active: makeTimer(
        id: 'active-1',
        status: TimerStatus.paused,
        allocatedDuration: 1500,
        elapsedTime: 1500,
      ),
    );

    await controller(container).extendTimer(by: const Duration(minutes: 5));

    expect(repository.calls, ['update:active-1', 'resume:active-1']);
    expect(repository.updated, const TimerUpdate(allocatedDuration: 1800));
  });

  test('연장 PATCH가 실패하면 재개하지 않고 예외를 던진다', () async {
    final container = boot(
      active: makeTimer(
        id: 'active-1',
        status: TimerStatus.paused,
        allocatedDuration: 1500,
        elapsedTime: 1500,
      ),
    );
    repository.error = Exception('422');

    await expectLater(
      controller(container).extendTimer(by: const Duration(minutes: 5)),
      throwsA(same(repository.error)),
    );
    expect(repository.calls, ['update:active-1']);
    expect(container.read(timerControllerProvider).hasError, isTrue);
  });

  group('연결된 Todo 목록', () {
    late int todoListReads;

    /// Todo 목록을 한 번 읽어 둔 컨테이너. 다시 읽을 때마다 [todoListReads]가 는다
    Future<ProviderContainer> bootWithTodos() async {
      todoListReads = 0;
      final container = ProviderContainer(
        overrides: [
          timerRepositoryProvider.overrideWithValue(repository),
          activeTimerProvider.overrideWithValue(const AsyncData(null)),
          timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
          todosProvider.overrideWith((ref, groupId) async {
            todoListReads++;
            return <TodoRead>[];
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(timerControllerProvider, (_, _) {});
      container.listen(todosProvider(null), (_, _) {});
      await container.read(todosProvider(null).future);
      return container;
    }

    void linkTo(String? todoId) =>
        repository.respond = (timerId, status) =>
            makeTimer(id: timerId, status: status).copyWith(todoId: todoId);

    test('Todo에 연결된 타이머를 완료하면 서버가 바꾼 Todo 상태를 보도록 Todo 목록을 다시 읽게 한다', () async {
      final container = await bootWithTodos();
      linkTo('todo-1');

      await controller(container).stopTimer(timerId: 't1');
      await container.read(todosProvider(null).future);

      expect(todoListReads, 2);
    });

    test('연결 없는 타이머를 완료하거나 연결된 타이머를 시작·일시정지·재개하면 Todo 목록을 다시 읽지 않는다', () async {
      final container = await bootWithTodos();

      linkTo(null);
      await controller(container).stopTimer(timerId: 't0');
      linkTo('todo-1');
      await controller(container).startTimer(relatedTodoId: 'todo-1');
      await controller(container).pauseTimer(timerId: 't1');
      await controller(container).resumeTimer(timerId: 't1');
      await container.read(todosProvider(null).future);

      expect(todoListReads, 1);
    });
  });
}
