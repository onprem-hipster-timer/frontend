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

  group('연장 중 완료', () {
    test('연장 응답을 기다리는 사이 완료하면 늘린 뒤 재개 대신 정지를 보낸다', () async {
      final container = boot(active: expired);
      final patched = Completer<void>();
      repository.gate = patched.future;

      final extend = controller(
        container,
      ).extendTimer(by: const Duration(minutes: 5));
      final stop = controller(container).stopTimer(timerId: 'active-1');
      await pumpEventQueue();
      expect(repository.calls, ['update:active-1']);

      patched.complete();
      await Future.wait([extend, stop]);

      expect(repository.calls, ['update:active-1', 'stop:active-1']);
    });

    test('완료는 정지 응답을 받은 뒤에 끝난다', () async {
      final container = boot(active: expired);
      final patched = Completer<void>();
      repository.gate = patched.future;
      final extend = controller(
        container,
      ).extendTimer(by: const Duration(minutes: 5));
      final stopped = Completer<void>();
      repository.gate = stopped.future;

      var done = false;
      final stop = controller(
        container,
      ).stopTimer(timerId: 'active-1').then((_) => done = true);
      patched.complete();
      await pumpEventQueue();

      expect(repository.calls, ['update:active-1', 'stop:active-1']);
      expect(done, isFalse);

      stopped.complete();
      await Future.wait([extend, stop]);
      expect(done, isTrue);
    });

    test('연장이 실패해도 완료는 보낸다', () async {
      final container = boot(active: expired);
      final patched = Completer<void>();
      repository.gate = patched.future;
      // 늘리기(PATCH)만 422로 거절한다
      repository.respond = (id, status) => status == TimerStatus.paused
          ? throw Exception('422')
          : makeTimer(id: id, status: status);

      final extend = controller(
        container,
      ).extendTimer(by: const Duration(minutes: 5));
      final stop = controller(container).stopTimer(timerId: 'active-1');
      patched.complete();

      await expectLater(extend, throwsA(isA<Exception>()));
      await stop;
      expect(repository.calls, ['update:active-1', 'stop:active-1']);
    });

    test('완료를 연달아 눌러도 정지는 한 번만 보내고 둘 다 그 응답을 기다린다', () async {
      final container = boot(active: expired);
      final stopped = Completer<void>();
      repository.gate = stopped.future;

      var done = 0;
      final first = controller(
        container,
      ).stopTimer(timerId: 'active-1').then((_) => done++);
      final second = controller(
        container,
      ).stopTimer(timerId: 'active-1').then((_) => done++);
      await pumpEventQueue();
      expect(done, 0);

      stopped.complete();
      await Future.wait([first, second]);

      expect(repository.calls, ['stop:active-1']);
      expect(done, 2);
    });

    test('정지가 실패하면 연달아 누른 완료도 그 실패를 받고, 다시 누르면 다시 보낸다', () async {
      final container = boot(active: expired);
      final stopped = Completer<void>();
      repository.gate = stopped.future;
      repository.error = Exception('503');

      final first = controller(container).stopTimer(timerId: 'active-1');
      final second = controller(container).stopTimer(timerId: 'active-1');
      stopped.complete();
      await expectLater(first, throwsA(same(repository.error)));
      await expectLater(second, throwsA(same(repository.error)));

      repository.error = null;
      await controller(container).stopTimer(timerId: 'active-1');

      expect(repository.calls, ['stop:active-1', 'stop:active-1']);
    });
  });
}
