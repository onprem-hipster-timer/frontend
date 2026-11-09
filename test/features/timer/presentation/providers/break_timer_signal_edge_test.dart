import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 서버 이벤트를 테스트에서 직접 흘려보내는 클라이언트
class _FakeWsClient extends Fake implements TimerWsClient {
  final events = StreamController<TimerWsEvent>.broadcast();

  @override
  Stream<TimerWsEvent> get messageStream => events.stream;
}

/// 휴식이 끝나야 하는 신호를 타이머 화면이 없을 때도 받는지
void main() {
  late FakeTimerRepository repository;
  late _FakeWsClient client;

  /// 서버 기준 시각
  late DateTime now;

  // 10:00에 시작해 5분 쓰고 일시정지한 타이머
  final paused = makeTimer(
    id: 't1',
    status: TimerStatus.paused,
    startedAt: DateTime.utc(2026, 11, 9, 10),
    allocatedDuration: 25 * 60,
    elapsedTime: 5 * 60,
  ).copyWith(updatedAt: DateTime.utc(2026, 11, 9, 10, 5));

  /// 다른 기기가 10:08에 재개한 [paused]
  final resumedElsewhere = paused.copyWith(
    status: TimerStatus.running,
    startedAt: DateTime.utc(2026, 11, 9, 10, 8),
    updatedAt: DateTime.utc(2026, 11, 9, 10, 8),
  );

  setUp(() {
    repository = FakeTimerRepository()..listActive = () async => [paused];
    client = _FakeWsClient();
    now = DateTime.utc(2026, 11, 9, 10, 10);
  });

  /// 타이머 화면 없이(휴식 말고 지켜보는 곳 없이) 시작한 컨테이너
  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        timerWsClientProvider.overrideWithValue(client),
        currentUserProvider.overrideWithValue(
          AuthUser(
            id: 'me',
            email: 'me@example.com',
            emailVerified: true,
            createdAt: DateTime.utc(2026),
          ),
        ),
        timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
        todosProvider.overrideWith((ref, groupId) async => <TodoRead>[]),
        serverClockProvider.overrideWithValue(
          ServerClock(deviceNow: () => now),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  BreakTimer breakTimer(ProviderContainer container) =>
      container.read(breakTimerProvider.notifier);

  /// 휴식 시계를 [by]만큼 옮긴 뒤 가짜 시간을 흘린다
  void elapse(FakeAsync async, Duration by) {
    now = now.add(by);
    async.elapse(by);
  }

  test('끊긴 사이 다른 기기가 재개한 타이머를 다시 연결해 받으면 휴식이 끝난다', () {
    fakeAsync((async) {
      final container = boot();
      breakTimer(container).start(const Duration(minutes: 5));
      async.elapse(Duration.zero);
      expect(container.read(breakTimerProvider), isNotNull);

      repository.listActive = () async => [resumedElsewhere];
      client.events.add(const TimerWsConnected());
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('0이 되어 확인을 기다리는 휴식도 다시 연결한 목록에 실행 중인 타이머가 있으면 끝난다', () {
    fakeAsync((async) {
      final container = boot();
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(minutes: 7));
      expect(container.read(breakTimerProvider), isNotNull);

      repository.listActive = () async => [resumedElsewhere];
      client.events.add(const TimerWsConnected());
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('다시 맞추는 중에 온 실행 이벤트도 맞춘 뒤 휴식을 끝낸다', () {
    fakeAsync((async) {
      final container = boot();
      breakTimer(container).start(const Duration(minutes: 5));
      async.elapse(Duration.zero);

      final list = Completer<List<TimerRead>>();
      repository.listActive = () => list.future;
      client.events
        ..add(const TimerWsConnected())
        ..add(
          TimerWsTimerEvent(
            id: 'm1',
            type: 'timer.updated',
            fromUser: 'me',
            timestamp: resumedElsewhere.updatedAt,
            payload: TimerWsEventPayload(
              action: 'resume',
              timer: resumedElsewhere,
            ),
          ),
        );
      async.elapse(Duration.zero);
      expect(container.read(breakTimerProvider), isNotNull);

      list.complete([paused]);
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('타이머 화면 없이 이 기기에서 재개하면 응답 전에 휴식이 끝난다', () {
    fakeAsync((async) {
      final response = Completer<void>();
      repository.gate = response.future;
      repository.respond = (id, status) => resumedElsewhere;
      final container = boot();
      container.listen(timerControllerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      async.elapse(Duration.zero);

      unawaited(
        container
            .read(timerControllerProvider.notifier)
            .resumeTimer(timerId: 't1'),
      );
      async.elapse(Duration.zero);

      expect(container.read(breakTimerProvider), isNull);
      response.complete();
      async.elapse(Duration.zero);
    });
  });

  test('휴식을 시작하기 전에 이미 실행 중인 타이머가 들어와 있으면 휴식을 두지 않는다', () {
    fakeAsync((async) {
      repository.listActive = () async => [resumedElsewhere];
      final container = boot();
      container.listen(myActiveTimersProvider, (_, _) {});
      async.elapse(Duration.zero);

      breakTimer(container).start(const Duration(minutes: 5));

      expect(container.read(breakTimerProvider), isNull);
    });
  });

  test('확인한 뒤 새로 시작한 휴식은 이전 끝 시각이 아니라 처음부터 센다', () {
    fakeAsync((async) {
      final container = boot();
      container.listen(breakTickerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(minutes: 6));
      expect(container.read(breakTickerProvider).requireValue, Duration.zero);

      breakTimer(container).end();
      elapse(async, const Duration(minutes: 1));
      breakTimer(container).start(const Duration(minutes: 5));
      async.elapse(Duration.zero);

      expect(
        container.read(breakTimerProvider)!.endAt,
        now.add(const Duration(minutes: 5)),
      );
      expect(
        container.read(breakTickerProvider).requireValue,
        const Duration(minutes: 5),
      );
    });
  });

  test('백그라운드에서 돌아오면 쌓인 틱이 아니라 저장한 끝 시각으로 남은 시간을 센다', () {
    fakeAsync((async) {
      final container = boot();
      final screen = container.listen(breakTickerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(seconds: 10));
      screen.close();
      async.elapse(Duration.zero);

      // 앱이 멈춘 동안 틱 없이 기기 시각만 2분 흘렀다
      now = now.add(const Duration(minutes: 2));
      container.listen(breakTickerProvider, (_, _) {});
      async.elapse(Duration.zero);

      expect(
        container.read(breakTickerProvider).requireValue,
        const Duration(minutes: 2, seconds: 50),
      );
      elapse(async, const Duration(seconds: 1));
      expect(
        container.read(breakTickerProvider).requireValue,
        const Duration(minutes: 2, seconds: 49),
      );
    });
  });

  test('휴식을 끝내면 남은 시간도 바로 0이 되고 더 세지 않는다', () {
    fakeAsync((async) {
      final container = boot();
      container.listen(breakTickerProvider, (_, _) {});
      breakTimer(container).start(const Duration(minutes: 5));
      elapse(async, const Duration(seconds: 3));

      breakTimer(container).end();
      async.elapse(Duration.zero);
      expect(container.read(breakTickerProvider).requireValue, Duration.zero);

      elapse(async, const Duration(seconds: 3));
      expect(container.read(breakTickerProvider).requireValue, Duration.zero);
      expect(async.periodicTimerCount, 0);
    });
  });
}
