import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/auth/auth_user.dart';
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

  ProviderContainer boot() {
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

  group('활성 타이머가 여럿이면', () {
    /// 서버 기준 현재 시각
    final serverNow = DateTime.utc(2026, 11, 9, 10, 10);

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

    /// [active]를 활성 타이머 목록으로 받아 둔 컨테이너
    Future<ProviderContainer> bootWith(List<TimerRead> active) async {
      repository.listActive = () async => active;
      final container = ProviderContainer(
        overrides: [
          timerRepositoryProvider.overrideWithValue(repository),
          timerWsClientProvider.overrideWithValue(null),
          currentUserProvider.overrideWithValue(null),
          timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => serverNow),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(myActiveTimersProvider, (_, _) {});
      await container.read(myActiveTimersProvider.future);
      return container;
    }

    /// 대시보드가 일시정지한 B를 보이게 고른다
    void focusB(ProviderContainer container) {
      container.listen(activeTimerProvider, (_, _) {});
      container.read(focusedTimerIdProvider.notifier).focus('b');
    }

    test('보이는 타이머가 일시정지여도 다른 타이머가 실행 중이면 휴식을 두지 않는다', () async {
      final container = await bootWith([runningA, pausedB]);
      focusB(container);
      expect(container.read(activeTimerProvider).value?.id, 'b');

      breakTimer(container).start(const Duration(minutes: 5));

      expect(container.read(breakTimerProvider), isNull);
    });

    test('휴식 중에 보이지 않는 타이머가 실행 중이 되면 휴식이 끝난다', () async {
      final pausedA = runningA.copyWith(
        status: TimerStatus.paused,
        elapsedTime: 2 * 60,
      );
      final container = await bootWith([pausedA, pausedB]);
      focusB(container);
      breakTimer(container).start(const Duration(minutes: 5));
      expect(container.read(breakTimerProvider), isNotNull);

      container
          .read(myActiveTimersProvider.notifier)
          .apply(runningA.copyWith(updatedAt: serverNow));

      expect(container.read(activeTimerProvider).value?.id, 'b');
      expect(container.read(breakTimerProvider), isNull);
    });

    test('시간이 끝난 실행 중 타이머는 휴식을 막지 않는다', () async {
      // 9:00에 시작한 25분 타이머는 서버 시각 10:10에 시간이 끝나 있다
      final timeUp = runningA.copyWith(startedAt: DateTime.utc(2026, 11, 9, 9));
      final container = await bootWith([timeUp]);

      breakTimer(container).start(const Duration(minutes: 5));

      expect(container.read(breakTimerProvider), isNotNull);
    });

    test('시간이 끝난 타이머와 일시정지 타이머만 있으면 휴식을 두고, 일시정지 타이머가 재개되면 끝낸다', () async {
      final timeUp = runningA.copyWith(startedAt: DateTime.utc(2026, 11, 9, 9));
      final container = await bootWith([timeUp, pausedB]);

      breakTimer(container).start(const Duration(minutes: 5));
      expect(container.read(breakTimerProvider), isNotNull);

      // 시간이 끝난 타이머를 다시 받아도 휴식은 그대로다
      container
          .read(myActiveTimersProvider.notifier)
          .apply(timeUp.copyWith(updatedAt: serverNow));
      expect(container.read(breakTimerProvider), isNotNull);

      container
          .read(myActiveTimersProvider.notifier)
          .apply(
            pausedB.copyWith(
              status: TimerStatus.running,
              startedAt: serverNow,
              updatedAt: serverNow,
            ),
          );
      expect(container.read(breakTimerProvider), isNull);
    });

    test('blocksBreak은 시간이 남은 실행 중 타이머가 하나라도 있을 때만 참이다', () {
      final timeUp = runningA.copyWith(startedAt: DateTime.utc(2026, 11, 9, 9));

      expect(blocksBreak([pausedB, runningA], serverNow), isTrue);
      expect(blocksBreak([pausedB, timeUp], serverNow), isFalse);
      expect(blocksBreak([pausedB], serverNow), isFalse);
      expect(blocksBreak(const [], serverNow), isFalse);
      // 끝나기 1초 전까지는 막는다
      expect(
        blocksBreak([runningA], DateTime.utc(2026, 11, 9, 10, 24, 59)),
        isTrue,
      );
      expect(
        blocksBreak([runningA], DateTime.utc(2026, 11, 9, 10, 25)),
        isFalse,
      );
    });
  });

  group('사용자가 바뀌면', () {
    AuthUser user(String id, {String? email}) => AuthUser(
      id: id,
      email: email ?? '$id@example.com',
      emailVerified: true,
      createdAt: DateTime.utc(2026),
    );

    final secret = makeTimer(
      id: 'a-1',
      status: TimerStatus.paused,
      startedAt: DateTime.utc(2026, 11, 9, 9),
    ).copyWith(title: 'A의 작업');

    /// 로그인한 사용자를 [_SignedIn]으로 바꿀 수 있는 컨테이너
    ProviderContainer bootSignedIn() {
      final container = ProviderContainer(
        overrides: [
          timerRepositoryProvider.overrideWithValue(repository),
          timerWsClientProvider.overrideWithValue(null),
          currentUserProvider.overrideWith((ref) => ref.watch(_signedIn)),
          timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
          serverClockProvider.overrideWithValue(
            ServerClock(deviceNow: () => now),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    void signIn(ProviderContainer container, AuthUser? signedIn) =>
        container.read(_signedIn.notifier).set(signedIn);

    test(
      '휴식 중 로그아웃하면 휴식을 버리고, 다음 사용자는 첫 조회가 실패해도 이전 사용자의 타이머를 보지 않는다',
      () async {
        repository.listActive = () async => [secret];
        final container = bootSignedIn();
        signIn(container, user('user-a'));
        // A가 일시정지한 타이머 위에서 휴식을 시작한 타이머 화면
        final screen = container.listen(activeTimerProvider, (_, _) {});
        await container.read(myActiveTimersProvider.future);
        breakTimer(container).start(const Duration(minutes: 5));
        expect(container.read(breakTimerProvider), isNotNull);

        // 로그아웃하면 타이머 화면이 사라지고 인증 없는 조회는 실패한다
        screen.close();
        repository.listActive = () async => throw Exception('401');
        signIn(container, null);
        await pumpEventQueue();

        expect(container.read(breakTimerProvider), isNull);

        // B의 첫 활성 타이머 조회가 네트워크 오류로 실패한다
        repository.listActive = () async => throw Exception('network');
        signIn(container, user('user-b'));
        await pumpEventQueue();

        expect(await container.read(myActiveTimersProvider.future), isEmpty);
        expect(container.read(activeTimerProvider).value, isNull);
      },
    );

    test('다른 사용자로 바로 바뀌어도 휴식을 버린다', () async {
      repository.listActive = () async => [secret];
      final container = bootSignedIn();
      signIn(container, user('user-a'));
      container.listen(breakTimerProvider, (_, _) {});
      await container.read(myActiveTimersProvider.future);
      breakTimer(container).start(const Duration(minutes: 5));

      signIn(container, user('user-b'));
      await pumpEventQueue();

      expect(container.read(breakTimerProvider), isNull);
    });

    test('사용자가 바뀐 뒤 시작한 휴식도 새 사용자의 타이머가 실행되면 끝난다', () async {
      final bTimer = makeTimer(id: 'b-1', status: TimerStatus.paused);
      repository.listActive = () async => [secret];
      final container = bootSignedIn();
      signIn(container, user('user-a'));
      container.listen(breakTimerProvider, (_, _) {});
      await container.read(myActiveTimersProvider.future);
      breakTimer(container).start(const Duration(minutes: 5));

      repository.listActive = () async => [bTimer];
      signIn(container, user('user-b'));
      await pumpEventQueue();
      expect(container.read(breakTimerProvider), isNull);
      expect(
        (await container.read(myActiveTimersProvider.future)).map((t) => t.id),
        ['b-1'],
      );

      breakTimer(container).start(const Duration(minutes: 5));
      expect(container.read(breakTimerProvider), isNotNull);
      container
          .read(myActiveTimersProvider.notifier)
          .apply(
            bTimer.copyWith(
              status: TimerStatus.running,
              updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
            ),
          );
      await pumpEventQueue();

      expect(container.read(breakTimerProvider), isNull);
    });

    test('로그아웃했다가 같은 사용자로 다시 들어와도 휴식은 다시 시작해야 한다', () async {
      repository.listActive = () async => [secret];
      final container = bootSignedIn();
      signIn(container, user('user-a'));
      container.listen(breakTimerProvider, (_, _) {});
      await container.read(myActiveTimersProvider.future);
      breakTimer(container).start(const Duration(minutes: 5));

      signIn(container, null);
      await pumpEventQueue();
      signIn(container, user('user-a'));
      await pumpEventQueue();

      expect(container.read(breakTimerProvider), isNull);
    });

    test('같은 사용자의 정보만 바뀌면 휴식은 그대로다', () async {
      repository.listActive = () async => [secret];
      final container = bootSignedIn();
      signIn(container, user('user-a'));
      container.listen(breakTimerProvider, (_, _) {});
      await container.read(myActiveTimersProvider.future);
      breakTimer(container).start(const Duration(minutes: 5));

      signIn(container, user('user-a', email: 'new@example.com'));
      await pumpEventQueue();

      expect(container.read(breakTimerProvider), isNotNull);
    });
  });

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

/// 테스트에서 바꾸는 로그인한 사용자
class _SignedIn extends Notifier<AuthUser?> {
  @override
  AuthUser? build() => null;

  void set(AuthUser? user) => state = user;
}

final _signedIn = NotifierProvider<_SignedIn, AuthUser?>(_SignedIn.new);
