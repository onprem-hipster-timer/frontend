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

    test('같은 updated_at이면 pause_history가 더 긴 쪽을 반영한다', () async {
      final c = await boot([_timer('t1', TimerStatus.running, minute: 1)]);
      List<Map<String, dynamic>> history(int length) => [
        for (var i = 0; i < length; i++) <String, dynamic>{},
      ];
      final paused = _timer(
        't1',
        TimerStatus.paused,
        minute: 2,
        elapsed: 120,
      ).copyWith(pauseHistory: history(2));
      final resumed = _timer(
        't1',
        TimerStatus.running,
        minute: 2,
      ).copyWith(pauseHistory: history(3));

      await emit(_event(paused));
      await emit(_event(resumed, action: 'resume'));
      expect(held(c, 't1').status, TimerStatus.running);

      // 같은 두 값이 거꾸로 와도 나중 상태를 둔다
      await emit(_event(paused));
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

  test('사용자가 바뀌면 새 사용자의 첫 조회가 실패해도 이전 사용자의 타이머를 보이지 않는다', () async {
    final c = await boot([_timer('a-1', TimerStatus.running, minute: 1)]);
    expect(held(c, 'a-1').status, TimerStatus.running);

    repository.listActive = () async => throw Exception('network');
    c.read(_signedIn.notifier).set(_user('other'));
    await pumpEventQueue();

    expect(await c.read(myActiveTimersProvider.future), isEmpty);
    expect(c.read(activeTimerProvider).value, isNull);
  });

  test('다시 맞추는 중에 사용자가 바뀌면 이전 사용자의 늦은 목록을 반영하지 않는다', () async {
    final c = await boot(const []);
    final list = Completer<List<TimerRead>>();
    repository.listActive = () => list.future;
    await emit(const TimerWsConnected());

    repository.listActive = () async => throw Exception('network');
    c.read(_signedIn.notifier).set(_user('other'));
    await pumpEventQueue();
    list.complete([_timer('a-1', TimerStatus.running, minute: 1)]);
    await pumpEventQueue();

    expect(await c.read(myActiveTimersProvider.future), isEmpty);
  });

  group('끝난 타이머', () {
    test('응답을 기다리는 사이 다시 맞춘 목록에서 빠지면 더 나중 응답이 와도 되살리지 않는다', () async {
      final c = await boot([_timer('t1', TimerStatus.running, minute: 1)]);
      final gate = Completer<void>();
      repository.gate = gate.future;
      repository.respond = (id, status) =>
          _timer(id, status, minute: 4, elapsed: 240);

      final pause = controller(c).pauseTimer(timerId: 't1');
      await pumpEventQueue();
      expect(held(c, 't1').status, TimerStatus.paused);
      // 다른 기기에서 끝내 다시 맞춘 목록에 없다
      repository.listActive = () async => [];
      await emit(const TimerWsConnected());
      expect(c.read(myActiveTimersProvider).requireValue, isEmpty);

      gate.complete();
      await pause;
      await pumpEventQueue();

      expect(c.read(myActiveTimersProvider).requireValue, isEmpty);
      expect(c.read(activeTimerProvider).value, isNull);
    });

    test('정지 이벤트를 받은 뒤 온 재개 응답은 updated_at이 나중이어도 되살리지 않는다', () async {
      final c = await boot([
        _timer('t1', TimerStatus.paused, minute: 1, elapsed: 60),
      ]);
      final gate = Completer<void>();
      repository.gate = gate.future;
      repository.respond = (id, status) =>
          _timer(id, status, minute: 4, elapsed: 60, startedAt: _at(4));

      final resume = controller(c).resumeTimer(timerId: 't1');
      await pumpEventQueue();
      await emit(
        _event(
          _timer('t1', TimerStatus.completed, minute: 3, elapsed: 60),
          action: 'stop',
        ),
      );
      gate.complete();
      await resume;
      await pumpEventQueue();

      expect(c.read(myActiveTimersProvider).requireValue, isEmpty);
      expect(
        c.read(myActiveTimersProvider.notifier).timer('t1')!.status,
        TimerStatus.completed,
      );
    });

    test('사용자가 바뀌면 다시 맞추기로 끝난 것으로 본 타이머를 잊는다', () async {
      final c = await boot([_timer('t1', TimerStatus.running, minute: 1)]);
      repository.listActive = () async => [];
      await emit(const TimerWsConnected());
      expect(c.read(myActiveTimersProvider).requireValue, isEmpty);

      repository.listActive = () async => [
        _timer('t1', TimerStatus.running, minute: 2),
      ];
      c.read(_signedIn.notifier).set(_user('other'));
      await pumpEventQueue();

      expect((await c.read(myActiveTimersProvider.future)).map((t) => t.id), [
        't1',
      ]);
    });
  });

  group('같은 초의 내 명령 응답', () {
    List<Map<String, dynamic>> history(int length) => [
      for (var i = 0; i < length; i++) <String, dynamic>{},
    ];

    /// 2분에 재개된 t1. [allocated]·[title]만 다르게 같은 순서의 값을 만든다
    TimerRead resumed({int allocated = 1500, String title = '작업'}) => _timer(
      't1',
      TimerStatus.running,
      minute: 2,
      startedAt: _at(2),
      elapsed: 60,
      allocated: allocated,
    ).copyWith(pauseHistory: history(2), title: title);

    /// 일시정지된 t1을 재개해 [resumed]를 가진 상태
    Future<ProviderContainer> bootResumed() async {
      final c = await boot([
        _timer(
          't1',
          TimerStatus.paused,
          minute: 1,
          elapsed: 60,
        ).copyWith(pauseHistory: history(1)),
      ]);
      repository.respond = (id, status) =>
          repository.calls.last.startsWith('update:')
          ? resumed(allocated: repository.updated!.allocatedDuration!)
          : resumed();
      await controller(c).resumeTimer(timerId: 't1');
      expect(held(c, 't1').status, TimerStatus.running);
      return c;
    }

    test('재개한 같은 초에 연장하면 늘린 시간을 보인다', () async {
      final c = await bootResumed();

      await controller(
        c,
      ).extendTimer(timerId: 't1', by: const Duration(minutes: 5));

      expect(repository.calls, ['list', 'resume:t1', 'update:t1']);
      expect(held(c, 't1').allocatedDuration, 1800);
      expect(c.read(activeTimerProvider).value!.allocatedDuration, 1800);
    });

    test('같은 순서의 이벤트는 내용이 달라도 버린다', () async {
      final c = await bootResumed();

      await emit(_event(resumed(title: '이벤트 제목'), action: 'update'));

      expect(held(c, 't1').title, isNot('이벤트 제목'));
    });

    test('같은 순서로 다시 맞춘 목록 값은 내용이 달라도 버린다', () async {
      final c = await bootResumed();
      repository.listActive = () async => [resumed(allocated: 3000)];

      await emit(const TimerWsConnected());

      expect(held(c, 't1').allocatedDuration, 1500);
    });
  });
}
