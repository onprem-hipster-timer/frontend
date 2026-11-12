import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';
import 'package:momeet/shared/domain/terms.dart';

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
    expect(repository.created?.title, '새 ${Terms.timer}');
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

  group('여러 할 일로 시작', () {
    TodoRead todo(String id, String title) =>
        makeTodo(id: id).copyWith(title: title);

    final report = todo('todo-1', '보고서 쓰기');
    final meeting = todo('todo-2', '회의 준비');
    final review = todo('todo-3', '코드 리뷰');

    /// [failing] 할 일의 만들기만 실패하는 응답
    void failFor(Set<String> failing) => repository.createResponse = (data) {
      if (failing.contains(data.todoId)) throw Exception('서버 오류');
      return makeTimer(id: 'timer-${data.todoId}', status: TimerStatus.running);
    };

    test('할 일마다 같은 시간과 그 할 일의 id·제목으로 차례대로 하나씩 만든다', () async {
      final container = boot();
      failFor(const {});

      final failed = await controller(container).startTimers(
        todos: [report, meeting, review],
        duration: const Duration(minutes: 45),
      );

      expect(failed, isEmpty);
      expect(repository.calls, ['create', 'create', 'create']);
      expect(
        repository.creates.map(
          (data) => (data.todoId, data.title, data.allocatedDuration),
        ),
        [
          ('todo-1', '보고서 쓰기', 45 * 60),
          ('todo-2', '회의 준비', 45 * 60),
          ('todo-3', '코드 리뷰', 45 * 60),
        ],
      );
      expect(container.read(timerControllerProvider).isLoading, isFalse);
    });

    test('일부가 실패해도 나머지를 보내고 실패한 할 일만 순서대로 돌려준다', () async {
      final container = boot();
      failFor({'todo-1', 'todo-3'});

      final failed = await controller(container).startTimers(
        todos: [report, meeting, review],
        duration: const Duration(minutes: 25),
      );

      expect(failed, [report, review]);
      expect(repository.creates.map((data) => data.todoId), [
        'todo-1',
        'todo-2',
        'todo-3',
      ]);
      expect(container.read(timerControllerProvider).isLoading, isFalse);
    });

    test('모두 실패하면 모든 할 일을 돌려주고 던지지 않는다', () async {
      final container = boot();
      failFor({'todo-1', 'todo-2'});

      final failed = await controller(container).startTimers(
        todos: [report, meeting],
        duration: const Duration(minutes: 25),
      );

      expect(failed, [report, meeting]);
    });

    test('보내는 동안 로딩 상태다', () async {
      final container = boot();
      failFor(const {});
      final gate = Completer<void>();
      repository.gate = gate.future;

      final starting = controller(container).startTimers(
        todos: [report, meeting],
        duration: const Duration(minutes: 25),
      );
      expect(container.read(timerControllerProvider).isLoading, isTrue);

      gate.complete();
      await starting;
      expect(container.read(timerControllerProvider).isLoading, isFalse);
    });
  });
}
