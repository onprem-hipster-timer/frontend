import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 서버 이벤트를 테스트에서 직접 흘려보내는 클라이언트
class _FakeWsClient extends Fake implements TimerWsClient {
  final events = StreamController<TimerWsEvent>.broadcast();

  @override
  Stream<TimerWsEvent> get messageStream => events.stream;
}

/// 테스트에서 바꾸는 로그인한 사용자
class _SignedIn extends Notifier<AuthUser?> {
  @override
  AuthUser? build() => _user('me');

  void set(AuthUser? user) => state = user;
}

final _signedIn = NotifierProvider<_SignedIn, AuthUser?>(_SignedIn.new);

AuthUser _user(String id) => AuthUser(
  id: id,
  email: '$id@example.com',
  emailVerified: true,
  createdAt: DateTime.utc(2026),
);

/// 서버 기준 지금
final _now = DateTime.utc(2026, 11, 6, 10, 5);

DateTime _at(int minute, [int second = 0]) =>
    DateTime.utc(2026, 11, 6, 10, minute, second);

/// [minute]분에 바뀐 타이머. 10:00에 시작했다
TimerRead _timer(
  String id,
  TimerStatus status, {
  required int minute,
  int elapsed = 0,
  DateTime? startedAt,
  int allocated = 1500,
}) => makeTimer(
  id: id,
  status: status,
  startedAt: startedAt ?? _at(0),
  elapsedTime: elapsed,
  allocatedDuration: allocated,
).copyWith(updatedAt: _at(minute));

int _seq = 0;

TimerWsTimerEvent _event(TimerRead timer, {String action = 'pause'}) =>
    TimerWsTimerEvent(
      id: 'm${_seq++}',
      type: 'timer.updated',
      fromUser: 'me',
      timestamp: timer.updatedAt,
      payload: TimerWsEventPayload(action: action, timer: timer),
    );

void main() {
  late FakeTimerRepository repository;
  late _FakeWsClient client;

  setUp(() {
    repository = FakeTimerRepository();
    client = _FakeWsClient();
  });

  Future<ProviderContainer> boot(List<TimerRead> active) async {
    repository.listActive = () async => active;
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        timerWsClientProvider.overrideWithValue(client),
        currentUserProvider.overrideWith((ref) => ref.watch(_signedIn)),
        timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
        todosProvider.overrideWith((ref, groupId) async => <TodoRead>[]),
        serverClockProvider.overrideWithValue(
          ServerClock(deviceNow: () => _now),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(myActiveTimersProvider, (_, _) {});
    container.listen(activeTimerProvider, (_, _) {});
    container.listen(timerControllerProvider, (_, _) {});
    await container.read(myActiveTimersProvider.future);
    return container;
  }

  TimerRead held(ProviderContainer c, String id) => c
      .read(myActiveTimersProvider)
      .requireValue
      .singleWhere((t) => t.id == id);

  TimerController controller(ProviderContainer c) =>
      c.read(timerControllerProvider.notifier);

  Future<void> emit(TimerWsEvent event) async {
    client.events.add(event);
    await pumpEventQueue();
  }

  group('늦게 온 REST 응답', () {
    test('다시 맞추는 사이 온 더 나중 이벤트는 그보다 늦게 끝난 이전 목록에 덮이지 않는다', () async {
      final c = await boot([_timer('t1', TimerStatus.running, minute: 1)]);
      final list = Completer<List<TimerRead>>();
      repository.listActive = () => list.future;

      await emit(const TimerWsConnected());
      await emit(
        _event(_timer('t1', TimerStatus.paused, minute: 3, elapsed: 180)),
      );
      list.complete([_timer('t1', TimerStatus.running, minute: 1)]);
      await pumpEventQueue();

      final shown = held(c, 't1');
      expect(shown.status, TimerStatus.paused);
      expect(displayElapsed(shown, _now), const Duration(seconds: 180));
    });

    test('다른 기기의 더 나중 이벤트가 먼저 오면 늦게 온 내 명령 응답이 되돌리지 않는다', () async {
      final c = await boot([_timer('t1', TimerStatus.running, minute: 1)]);
      final gate = Completer<void>();
      repository.gate = gate.future;
      repository.respond = (id, status) =>
          _timer(id, status, minute: 2, elapsed: 120);

      final pause = controller(c).pauseTimer(timerId: 't1');
      await pumpEventQueue();
      // 다른 기기가 그 뒤 다시 재개했다
      await emit(
        _event(
          _timer(
            't1',
            TimerStatus.running,
            minute: 4,
            elapsed: 120,
            startedAt: _at(4),
          ),
          action: 'resume',
        ),
      );
      gate.complete();
      await pause;

      final shown = held(c, 't1');
      expect(shown.status, TimerStatus.running);
      expect(displayElapsed(shown, _now), const Duration(seconds: 180));
    });

    test('같은 updated_at이면 나중에 도착한 쪽을 반영한다 (규칙: 같거나 나중이면 반영)', () async {
      final c = await boot([_timer('t1', TimerStatus.running, minute: 1)]);

      await emit(
        _event(_timer('t1', TimerStatus.paused, minute: 2, elapsed: 120)),
      );
      await emit(
        _event(_timer('t1', TimerStatus.running, minute: 2), action: 'resume'),
      );

      expect(held(c, 't1').status, TimerStatus.running);
    });
  });

  group('재개 실패 되돌리기', () {
    test('응답을 기다리는 사이 다른 기기의 이벤트가 오면 실패해도 그 값을 둔다', () async {
      final c = await boot([
        _timer('t1', TimerStatus.paused, minute: 1, elapsed: 60),
      ]);
      final gate = Completer<void>();
      repository.gate = gate.future;
      repository.error = Exception('409');

      final resume = controller(c).resumeTimer(timerId: 't1');
      await pumpEventQueue();
      expect(held(c, 't1').status, TimerStatus.running);
      // 다른 기기가 먼저 재개했다
      await emit(
        _event(
          _timer(
            't1',
            TimerStatus.running,
            minute: 3,
            elapsed: 60,
            startedAt: _at(3),
          ),
          action: 'resume',
        ),
      );
      gate.complete();
      await expectLater(resume, throwsA(isA<Exception>()));

      final shown = held(c, 't1');
      expect(shown.status, TimerStatus.running);
      expect(shown.startedAt, _at(3));
      expect(displayElapsed(shown, _now), const Duration(seconds: 180));
    });

    test('응답을 기다리는 사이 연결된 할 일만 바뀌어도 실패하면 일시정지로 돌아가고 바뀐 할 일은 둔다', () async {
      final todo = makeTodo(id: 'todo-1');
      final c = await boot([
        _timer(
          't1',
          TimerStatus.paused,
          minute: 1,
          elapsed: 60,
        ).copyWith(todoId: todo.id, todo: todo),
      ]);
      final gate = Completer<void>();
      repository.gate = gate.future;
      repository.error = Exception('409');

      final resume = controller(c).resumeTimer(timerId: 't1');
      await pumpEventQueue();
      final renamed = todo.copyWith(title: '바뀐 할 일');
      c.read(myActiveTimersProvider.notifier).updateTodo(renamed);
      gate.complete();
      await expectLater(resume, throwsA(isA<Exception>()));

      final shown = held(c, 't1');
      expect(shown.status, TimerStatus.paused);
      expect(displayElapsed(shown, _now), const Duration(seconds: 60));
      expect(shown.todo, renamed);
    });
  });

  test('연장해 다시 실행한 뒤 늦게 온 시간 종료 이벤트는 버린다', () async {
    final c = await boot([
      _timer('t1', TimerStatus.paused, minute: 1, elapsed: 1500),
    ]);
    var call = 0;
    repository.respond = (id, status) => call++ == 0
        ? _timer(id, status, minute: 2, elapsed: 1500, allocated: 1800)
        : _timer(
            id,
            status,
            minute: 3,
            elapsed: 1500,
            allocated: 1800,
            startedAt: _at(3),
          );

    await controller(
      c,
    ).extendTimer(timerId: 't1', by: const Duration(minutes: 5));
    await emit(
      _event(
        _timer('t1', TimerStatus.paused, minute: 1, elapsed: 1500),
        action: 'expire',
      ),
    );

    final shown = held(c, 't1');
    expect(shown.status, TimerStatus.running);
    expect(displayRemaining(shown, _now), const Duration(minutes: 3));
  });

  test('고른 타이머가 끝나면 실행 중인 다른 타이머를 그 진행 그대로 보인다', () async {
    final running = _timer(
      't2',
      TimerStatus.running,
      minute: 1,
      elapsed: 30,
      startedAt: _at(1),
    );
    final c = await boot([
      running,
      _timer('t1', TimerStatus.paused, minute: 1, elapsed: 100),
    ]);
    c.read(focusedTimerIdProvider.notifier).focus('t1');
    repository.respond = (id, status) =>
        _timer(id, status, minute: 4, elapsed: 100);

    await controller(c).stopTimer(timerId: 't1');

    final shown = c.read(activeTimerProvider).requireValue!;
    expect(shown.id, 't2');
    expect(displayElapsed(shown, _now), const Duration(seconds: 30 + 240));
  });

  group('명령 응답을 기다리는 사이 다시 맞추기', () {
    test('응답이 다시 맞추는 중에 오면 맞춘 뒤 반영해 응답 값으로 끝난다', () async {
      final c = await boot([_timer('t1', TimerStatus.running, minute: 1)]);
      final gate = Completer<void>();
      repository.gate = gate.future;
      repository.respond = (id, status) =>
          _timer(id, status, minute: 2, elapsed: 120);
      final list = Completer<List<TimerRead>>();
      repository.listActive = () => list.future;

      final pause = controller(c).pauseTimer(timerId: 't1');
      await pumpEventQueue();
      await emit(const TimerWsConnected());
      gate.complete();
      await pause;
      // 일시정지 전에 읽은 목록
      list.complete([_timer('t1', TimerStatus.running, minute: 1)]);
      await pumpEventQueue();

      final shown = held(c, 't1');
      expect(shown.status, TimerStatus.paused);
      expect(displayElapsed(shown, _now), const Duration(seconds: 120));
    });

    test('다시 맞추는 중에 명령이 실패하면 목록의 값으로 끝난다', () async {
      final c = await boot([
        _timer('t1', TimerStatus.running, minute: 1, elapsed: 10),
      ]);
      final gate = Completer<void>();
      repository.gate = gate.future;
      repository.error = Exception('500');
      final list = Completer<List<TimerRead>>();
      repository.listActive = () => list.future;

      final pause = controller(c).pauseTimer(timerId: 't1');
      await pumpEventQueue();
      await emit(const TimerWsConnected());
      gate.complete();
      await expectLater(pause, throwsA(isA<Exception>()));
      list.complete([
        _timer('t1', TimerStatus.running, minute: 1, elapsed: 10),
      ]);
      await pumpEventQueue();

      final shown = held(c, 't1');
      expect(shown.status, TimerStatus.running);
      expect(displayElapsed(shown, _now), const Duration(seconds: 310));
    });
  });
}
