import 'dart:async';

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

  final expired = makeTimer(
    id: 'active-1',
    status: TimerStatus.paused,
    allocatedDuration: 1500,
    elapsedTime: 1500,
  );

  test('PATCH 응답이 아직 RUNNING이면 재개를 보내지 않는다', () async {
    final container = boot(active: expired);
    repository.respond = (id, _) => makeTimer(
      id: id,
      status: TimerStatus.running,
      allocatedDuration: 1800,
      elapsedTime: 0,
    );

    await controller(container).extendTimer(by: const Duration(minutes: 5));

    expect(repository.calls, ['update:active-1']);
  });

  test('연장이 진행 중일 때 다시 누르면 한 번만 연장한다', () async {
    final container = boot(active: expired);
    final gate = Completer<void>();
    repository.gate = gate.future;

    final first = controller(
      container,
    ).extendTimer(by: const Duration(minutes: 5));
    final second = controller(
      container,
    ).extendTimer(by: const Duration(minutes: 5));
    gate.complete();
    await Future.wait([first, second]);

    expect(repository.calls, ['update:active-1', 'resume:active-1']);
  });

  test('연장할 타이머가 없으면 예외를 던지고 아무것도 보내지 않는다', () async {
    final container = boot();

    await expectLater(
      controller(container).extendTimer(by: const Duration(minutes: 5)),
      throwsA(isA<Exception>()),
    );
    expect(repository.calls, isEmpty);
  });
}
