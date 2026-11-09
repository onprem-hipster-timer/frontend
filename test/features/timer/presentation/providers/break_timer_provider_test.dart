import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/network/server_clock.dart';
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

  /// 가짜 시계 [async]에서 [active]를 활성 타이머로 받는 컨테이너
  ProviderContainer bootOn(
    FakeAsync async, {
    List<TimerRead> active = const [],
  }) {
    repository.listActive = () async => active;
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        timerWsClientProvider.overrideWithValue(null),
        currentUserProvider.overrideWithValue(null),
        timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
        serverClockProvider.overrideWithValue(
          ServerClock(deviceNow: () => now),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// 휴식 시계를 [by]만큼 옮긴 뒤 가짜 시간을 흘린다.
  ///
  /// `Stream.periodic`의 틱은 가짜 시간의 정수 초보다 조금 일찍 오므로 시계를 먼저 옮긴다.
  void elapse(FakeAsync async, Duration by) {
    now = now.add(by);
    async.elapse(by);
  }

  Duration remaining(ProviderContainer container) =>
      container.read(breakTickerProvider).requireValue;

  BreakTimer breakTimer(ProviderContainer container) =>
      container.read(breakTimerProvider.notifier);

  test('시작하면 남은 시간을 바로 내고 1초마다 줄인다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      container.listen(breakTickerProvider, (_, _) {});

      breakTimer(container).start(const Duration(minutes: 5));
      async.elapse(Duration.zero);

      expect(remaining(container), const Duration(minutes: 5));

      elapse(async, const Duration(seconds: 3));

      expect(remaining(container), const Duration(minutes: 4, seconds: 57));
    });
  });

  test('0이 되면 0에 머물고 휴식은 끝낼 때까지 남는다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      container.listen(breakTickerProvider, (_, _) {});

      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(minutes: 5));

      expect(remaining(container), Duration.zero);

      elapse(async, const Duration(minutes: 1));

      expect(remaining(container), Duration.zero);
      expect(container.read(breakTimerProvider), isNotNull);
    });
  });

  test('끝내면 휴식이 없고 남은 시간은 0이다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      container.listen(breakTickerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(seconds: 10));

      breakTimer(container).end();
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
      expect(remaining(container), Duration.zero);
    });
  });

  test('남은 시간을 보는 곳이 없어지면 틱을 바로 멈춘다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      final screen = container.listen(breakTickerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(seconds: 2));

      screen.close();
      async.elapse(Duration.zero);

      expect(async.pendingTimers, isEmpty);
    });
  });

  test('다시 시작하면 진행 중인 휴식을 새 휴식으로 바꾼다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      container.listen(breakTickerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(minutes: 1));

      breakTimer(container).start(const Duration(minutes: 10));
      async.elapse(Duration.zero);

      expect(
        container.read(breakTimerProvider)?.total,
        const Duration(minutes: 10),
      );
      expect(remaining(container), const Duration(minutes: 10));

      elapse(async, const Duration(minutes: 5));

      expect(remaining(container), const Duration(minutes: 5));
    });
  });

  test('활성 타이머가 실행 중이 되면 휴식이 끝난다', () {
    fakeAsync((async) {
      final paused = makeTimer(id: 't1', status: TimerStatus.paused);
      final container = bootOn(async, active: [paused]);
      container.listen(breakTimerProvider, (_, _) {});
      container.listen(activeTimerProvider, (_, _) {});
      async.elapse(Duration.zero);
      breakTimer(container).start(const Duration(minutes: 5));

      // 타이머 목록에서 재개한 응답
      container
          .read(myActiveTimersProvider.notifier)
          .apply(
            paused.copyWith(
              status: TimerStatus.running,
              updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
            ),
          );
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('타이머 화면이 보이지 않는 사이 타이머가 실행됐다가 다시 일시정지해도 휴식이 끝나 있다', () {
    fakeAsync((async) {
      final paused = makeTimer(id: 't1', status: TimerStatus.paused);
      final container = bootOn(async, active: [paused]);
      // 휴식을 보여 주던 타이머 화면의 구독
      final screen = [
        container.listen(breakTimerProvider, (_, _) {}),
        container.listen(activeTimerProvider, (_, _) {}),
      ];
      async.elapse(Duration.zero);
      breakTimer(container).start(const Duration(minutes: 5));

      // 다른 탭으로 가면 화면의 구독이 멈춘다
      for (final subscription in screen) {
        subscription.pause();
      }
      async.elapse(Duration.zero);

      // Todo 화면에서 재개했다가 다시 일시정지한다
      final timers = container.read(myActiveTimersProvider.notifier);
      timers.apply(
        paused.copyWith(
          status: TimerStatus.running,
          updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
        ),
      );
      async.elapse(Duration.zero);
      timers.apply(paused.copyWith(updatedAt: DateTime.utc(2026, 1, 1, 0, 2)));
      async.elapse(Duration.zero);

      // 타이머 화면으로 돌아온다
      for (final subscription in screen) {
        subscription.resume();
      }
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('일시정지한 타이머는 휴식을 끝내지 않는다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      container.listen(activeTimerProvider, (_, _) {});
      async.elapse(Duration.zero);
      breakTimer(container).start(const Duration(minutes: 5));

      // 다른 기기에서 시작해 일시정지한 타이머
      container
          .read(myActiveTimersProvider.notifier)
          .apply(makeTimer(id: 't2', status: TimerStatus.paused));
      async.elapse(Duration.zero);

      expect(
        container.read(activeTimerProvider).value?.status,
        TimerStatus.paused,
      );
      expect(container.read(breakTimerProvider), isNotNull);
    });
  });

  test('활성 타이머가 실행 중이면 휴식을 두지 않는다', () {
    fakeAsync((async) {
      final container = bootOn(
        async,
        active: [makeTimer(id: 't1', status: TimerStatus.running)],
      );
      container.listen(activeTimerProvider, (_, _) {});
      async.elapse(Duration.zero);

      breakTimer(container).start(const Duration(minutes: 5));

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('남은 시간은 초 단위로 올리고 0 아래로 내려가지 않는다', () {
    final session = BreakSession(
      endAt: DateTime(2026, 11, 9, 10, 5),
      total: const Duration(minutes: 5),
    );

    expect(
      session.remainingAt(DateTime(2026, 11, 9, 10, 0, 0, 300)),
      const Duration(minutes: 5),
    );
    expect(
      session.remainingAt(DateTime(2026, 11, 9, 10, 4, 59, 500)),
      const Duration(seconds: 1),
    );
    expect(session.remainingAt(DateTime(2026, 11, 9, 10, 5)), Duration.zero);
    expect(session.remainingAt(DateTime(2026, 11, 9, 10, 6)), Duration.zero);
  });

  group('기기 시계가 서버와 어긋나도 서버 기준 시각으로 센다', () {
    for (final (name, skew) in [
      ('늦은', const Duration(minutes: -10)),
      ('빠른', const Duration(minutes: 10)),
    ]) {
      test('기기 시계가 $name 기기에서 끝나는 시각은 서버 시각 기준이고 길이는 그대로다', () {
        fakeAsync((async) {
          var server = DateTime.utc(2026, 11, 9, 10);
          var device = server.add(skew);
          final clock = ServerClock(deviceNow: () => device)
            ..addSample(serverDate: server, sentAt: device, receivedAt: device);
          final container = ProviderContainer(
            overrides: [
              timerRepositoryProvider.overrideWithValue(repository),
              timerWsClientProvider.overrideWithValue(null),
              currentUserProvider.overrideWithValue(null),
              timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
              serverClockProvider.overrideWithValue(clock),
            ],
          );
          addTearDown(container.dispose);
          container.listen(breakTickerProvider, (_, _) {});
          void pass(Duration by) {
            server = server.add(by);
            device = device.add(by);
            async.elapse(by);
          }

          breakTimer(container).start(const Duration(minutes: 5));
          async.elapse(Duration.zero);

          expect(
            container.read(breakTimerProvider)!.endAt,
            clock.now().add(const Duration(minutes: 5)),
          );
          expect(
            container.read(breakTimerProvider)!.endAt.difference(server),
            const Duration(minutes: 5, milliseconds: 500),
          );

          pass(const Duration(minutes: 4, seconds: 58));
          expect(remaining(container), const Duration(seconds: 2));
          pass(const Duration(seconds: 2));
          expect(remaining(container), Duration.zero);
        });
      });

      test(
        '휴식 중 기기 시계를 ${skew.isNegative ? '뒤로' : '앞으로'} 옮겨도 서버 시각을 다시 맞추면 남은 시간이 그대로다',
        () {
          fakeAsync((async) {
            var server = DateTime.utc(2026, 11, 9, 10);
            var device = server;
            final clock = ServerClock(deviceNow: () => device);
            final container = ProviderContainer(
              overrides: [
                timerRepositoryProvider.overrideWithValue(repository),
                timerWsClientProvider.overrideWithValue(null),
                currentUserProvider.overrideWithValue(null),
                timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
                serverClockProvider.overrideWithValue(clock),
              ],
            );
            addTearDown(container.dispose);
            container.listen(breakTickerProvider, (_, _) {});
            void pass(Duration by) {
              server = server.add(by);
              device = device.add(by);
              async.elapse(by);
            }

            breakTimer(container).start(const Duration(minutes: 5));
            pass(const Duration(minutes: 1));
            expect(remaining(container), const Duration(minutes: 4));

            // 기기 시계만 옮기고, 그 뒤 타이머 응답들로 서버 시각을 다시 맞춘다
            device = device.add(skew);
            for (var i = 0; i < 5; i++) {
              clock.addSample(
                serverDate: server,
                sentAt: device,
                receivedAt: device,
              );
            }
            pass(const Duration(seconds: 1));

            expect(
              remaining(container),
              const Duration(minutes: 3, seconds: 59),
            );
          });
        },
      );
    }
  });
}
