import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

void main() {
  late FakeTimerRepository repository;

  /// 휴식 시계가 읽는 시각
  late DateTime now;

  setUp(() {
    repository = FakeTimerRepository();
    now = DateTime(2026, 11, 9, 10);
  });

  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        timerWsClientProvider.overrideWithValue(null),
        currentUserProvider.overrideWithValue(null),
        timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
        breakClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// 휴식 시계를 [by]만큼 옮긴 뒤 가짜 시간을 흘린다.
  void elapse(FakeAsync async, Duration by) {
    now = now.add(by);
    async.elapse(by);
  }

  BreakTimer breakTimer(ProviderContainer container) =>
      container.read(breakTimerProvider.notifier);

  Duration remaining(ProviderContainer container) =>
      container.read(breakTickerProvider).requireValue;

  final paused = makeTimer(id: 't1', status: TimerStatus.paused);

  /// [paused]를 다시 실행한 응답
  final resumed = paused.copyWith(
    status: TimerStatus.running,
    updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
  );

  test('휴식을 지켜보는 곳이 없어도 타이머가 실행되면 휴식이 끝난다', () {
    fakeAsync((async) {
      repository.listActive = () async => [paused];
      final container = boot();

      breakTimer(container).start(const Duration(minutes: 5));
      async.elapse(Duration.zero);
      expect(container.read(breakTimerProvider), isNotNull);

      container.read(myActiveTimersProvider.notifier).apply(resumed);
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('0이 되어 확인을 기다리는 휴식도 타이머가 실행되면 끝난다', () {
    fakeAsync((async) {
      repository.listActive = () async => [paused];
      final container = boot();
      container.listen(breakTimerProvider, (_, _) {});
      async.elapse(Duration.zero);

      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(minutes: 6));
      expect(container.read(breakTimerProvider), isNotNull);

      container.read(myActiveTimersProvider.notifier).apply(resumed);
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  for (final (label, status, ends) in [
    ('실행 중인', TimerStatus.running, true),
    ('일시정지한', TimerStatus.paused, false),
  ]) {
    test('활성 타이머를 읽는 중에 시작한 휴식은 $label 타이머를 받으면 '
        '${ends ? '끝난다' : '남는다'}', () {
      fakeAsync((async) {
        final list = Completer<List<TimerRead>>();
        repository.listActive = () => list.future;
        final container = boot();
        container.listen(breakTimerProvider, (_, _) {});
        container.listen(activeTimerProvider, (_, _) {});

        breakTimer(container).start(const Duration(minutes: 5));
        async.elapse(Duration.zero);
        expect(container.read(activeTimerProvider).isLoading, isTrue);
        expect(container.read(breakTimerProvider), isNotNull);

        list.complete([makeTimer(id: 't1', status: status)]);
        async.elapse(Duration.zero);

        expect(container.read(activeTimerProvider).value?.status, status);
        expect(container.read(breakTimerProvider), ends ? isNull : isNotNull);
      });
    });
  }

  test('활성 타이머를 읽지 못해도 휴식은 이어지고 나중에 실행 중인 타이머를 받으면 끝난다', () {
    fakeAsync((async) {
      repository.listActive = () async => throw Exception('503');
      final container = boot();
      container.listen(breakTimerProvider, (_, _) {});
      container.listen(breakTickerProvider, (_, _) {});

      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(seconds: 10));

      expect(container.read(breakTimerProvider), isNotNull);
      expect(remaining(container), const Duration(minutes: 4, seconds: 50));

      container
          .read(myActiveTimersProvider.notifier)
          .apply(makeTimer(id: 't1', status: TimerStatus.running));
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('재개를 누르면 응답 전에 휴식이 끝나고 재개가 실패해도 되살리지 않는다', () {
    fakeAsync((async) {
      final response = Completer<void>();
      repository.listActive = () async => [paused];
      repository.gate = response.future;
      repository.error = Exception('503');
      final container = boot();
      container.listen(breakTimerProvider, (_, _) {});
      container.listen(activeTimerProvider, (_, _) {});
      container.listen(timerControllerProvider, (_, _) {});
      async.elapse(Duration.zero);
      breakTimer(container).start(const Duration(minutes: 5));

      Object? failure;
      container
          .read(timerControllerProvider.notifier)
          .resumeTimer()
          .catchError((Object error) => failure = error);
      async.elapse(Duration.zero);

      expect(
        container.read(activeTimerProvider).value?.status,
        TimerStatus.running,
      );
      expect(container.read(breakTimerProvider), isNull);

      response.complete();
      async.elapse(Duration.zero);

      expect(failure, isNotNull);
      expect(
        container.read(activeTimerProvider).value?.status,
        TimerStatus.paused,
      );
      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('휴식이 없을 때 끝내거나 두 번 끝내도 아무 일이 없다', () {
    fakeAsync((async) {
      final container = boot();
      container.listen(breakTickerProvider, (_, _) {});

      breakTimer(container).end();
      breakTimer(container).end();
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
      expect(remaining(container), Duration.zero);
    });
  });

  for (final (label, total) in [
    ('0분', Duration.zero),
    ('-1분', const Duration(minutes: -1)),
  ]) {
    test('$label으로 시작하면 남은 시간은 바로 0이고 휴식은 끝낼 때까지 남는다', () {
      fakeAsync((async) {
        final container = boot();
        container.listen(breakTickerProvider, (_, _) {});

        breakTimer(container).start(total);
        async.elapse(Duration.zero);

        expect(container.read(breakTimerProvider), isNotNull);
        expect(remaining(container), Duration.zero);
      });
    });
  }

  test('남은 시간을 다시 지켜보면 그동안 흐른 시간을 바로 반영한다', () {
    fakeAsync((async) {
      final container = boot();
      final screen = container.listen(breakTickerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(seconds: 10));

      screen.close();
      elapse(async, const Duration(minutes: 2));
      container.listen(breakTickerProvider, (_, _) {});
      async.elapse(Duration.zero);

      expect(remaining(container), const Duration(minutes: 2, seconds: 50));
    });
  });

  test('휴식이 없으면 남은 시간을 1초마다 다시 계산하지 않는다', () {
    fakeAsync((async) {
      final container = boot();
      container.listen(breakTickerProvider, (_, _) {});
      async.elapse(Duration.zero);

      expect(async.periodicTimerCount, 0);

      breakTimer(container).start(const Duration(minutes: 5));
      async.elapse(Duration.zero);
      expect(async.periodicTimerCount, 1);

      breakTimer(container).end();
      async.elapse(Duration.zero);
      expect(async.periodicTimerCount, 0);
    });
  });
}
