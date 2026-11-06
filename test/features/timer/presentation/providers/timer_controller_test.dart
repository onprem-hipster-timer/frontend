import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/timer_fixtures.dart';

/// 타이머 명령 REST 호출을 기록하는 리포지토리
class _FakeTimerRepository implements TimerRepository {
  final calls = <String>[];
  TimerCreate? created;
  Object? error;

  TimerRead _respond(String call, TimerStatus status) {
    calls.add(call);
    if (error != null) throw error!;
    return makeTimer(id: 'timer-1', status: status);
  }

  @override
  Future<TimerRead> createTimer(TimerCreate data) async {
    created = data;
    return _respond('create', TimerStatus.running);
  }

  @override
  Future<TimerRead> pauseTimer(String timerId) async =>
      _respond('pause:$timerId', TimerStatus.paused);

  @override
  Future<TimerRead> resumeTimer(String timerId) async =>
      _respond('resume:$timerId', TimerStatus.running);

  @override
  Future<TimerRead> stopTimer(String timerId) async =>
      _respond('stop:$timerId', TimerStatus.completed);

  @override
  Future<TimerRead?> getActiveTimer() async => null;

  @override
  Future<List<TimerRead>> getTimerHistory() async => [];

  @override
  Future<List<TimerRead>> listTimers({
    List<String>? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  @override
  Future<TimerRead> updateTimer(String timerId, TimerUpdate data) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTimer(String timerId) => throw UnimplementedError();
}

void main() {
  late _FakeTimerRepository repository;

  setUp(() => repository = _FakeTimerRepository());

  ProviderContainer boot({TimerRead? active}) {
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        activeTimerProvider.overrideWith((ref) => Stream.value(active)),
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
    expect(repository.created?.allocatedDuration, 3600);
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
    await container.read(activeTimerProvider.future);

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
}
