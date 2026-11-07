import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
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
}
