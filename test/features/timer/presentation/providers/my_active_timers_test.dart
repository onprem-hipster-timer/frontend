import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/auth/auth_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import '../../../../helpers/fake_timer_repository.dart';
import '../../../../helpers/schedule_fixtures.dart';
import '../../../../helpers/timer_fixtures.dart';

/// 서버 이벤트를 테스트에서 직접 흘려보내는 클라이언트
class _FakeWsClient extends Fake implements TimerWsClient {
  final events = StreamController<TimerWsEvent>.broadcast();

  @override
  Stream<TimerWsEvent> get messageStream => events.stream;
}

const _me = 'user-me';

TimerRead _timer(String id, TimerStatus status, {required int minute}) =>
    makeTimer(
      id: id,
      status: status,
      startedAt: DateTime.utc(2026, 11, 6, 10),
    ).copyWith(updatedAt: DateTime.utc(2026, 11, 6, 10, minute));

/// Todo를 포함해 읽은 REST 응답
TimerRead _read(
  String id,
  TimerStatus status, {
  required int minute,
  String todoId = 'todo-1',
}) => _timer(id, status, minute: minute).copyWith(
  todoId: todoId,
  todo: makeTodo(id: todoId),
);

int _seq = 0;

TimerWsTimerEvent _event(
  TimerRead timer, {
  String fromUser = _me,
  String action = 'update',
}) => TimerWsTimerEvent(
  id: 'm${_seq++}',
  type: 'timer.updated',
  fromUser: fromUser,
  timestamp: timer.updatedAt,
  payload: TimerWsEventPayload(action: action, timer: timer),
);

TimerWsTimerEvent _deleted(String timerId) => TimerWsTimerEvent(
  id: 'm${_seq++}',
  type: 'timer.deleted',
  fromUser: _me,
  timestamp: DateTime.utc(2026, 11, 6, 11),
  payload: TimerWsEventPayload(action: 'delete', timerId: timerId),
);

void main() {
  late FakeTimerRepository repository;
  late _FakeWsClient client;

  setUp(() {
    repository = FakeTimerRepository();
    client = _FakeWsClient();
  });

  Future<ProviderContainer> boot() async {
    final container = ProviderContainer(
      overrides: [
        timerRepositoryProvider.overrideWithValue(repository),
        timerWsClientProvider.overrideWithValue(client),
        currentUserProvider.overrideWithValue(
          AuthUser(
            id: _me,
            email: 'me@example.com',
            emailVerified: true,
            createdAt: DateTime.utc(2026),
          ),
        ),
        timerHistoryProvider.overrideWith((ref) async => <TimerRead>[]),
      ],
    );
    addTearDown(container.dispose);
    container.listen(myActiveTimersProvider, (_, _) {});
    await container.read(myActiveTimersProvider.future);
    return container;
  }

  List<TimerRead> active(ProviderContainer container) =>
      container.read(myActiveTimersProvider).requireValue;

  Future<void> emit(TimerWsEvent event) async {
    client.events.add(event);
    await pumpEventQueue();
  }

  test('처음에 REST로 내 활성 타이머를 가져온다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];

    final container = await boot();

    expect(active(container).single.id, 't1');
    expect(container.read(activeTimerProvider).value?.id, 't1');
  });

  test('내 이벤트를 반영하고 updated_at이 이전인 이벤트는 버린다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    final container = await boot();

    await emit(_event(_timer('t1', TimerStatus.paused, minute: 3)));
    await emit(_event(_timer('t1', TimerStatus.running, minute: 2)));

    expect(active(container).single.status, TimerStatus.paused);
  });

  test('친구의 이벤트는 반영하지 않는다', () async {
    final container = await boot();

    await emit(
      _event(_timer('f1', TimerStatus.running, minute: 1), fromUser: 'friend'),
    );

    expect(active(container), isEmpty);
    expect(container.read(activeTimerProvider).value, isNull);
  });

  test('timer.deleted면 빼고, 그 뒤에 온 같은 ID 이벤트는 버린다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    final container = await boot();

    await emit(_deleted('t1'));
    await emit(_event(_timer('t1', TimerStatus.running, minute: 9)));

    expect(active(container), isEmpty);
  });

  test('(재)연결되면 REST로 다시 맞춘다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    final container = await boot();

    repository.listActive = () async => [
      _timer('t2', TimerStatus.paused, minute: 2),
    ];
    await emit(const TimerWsConnected());

    expect(repository.calls.where((c) => c == 'list'), hasLength(2));
    expect(active(container).map((t) => t.id), ['t2']);
  });

  test('다시 맞추는 동안 들어온 이벤트는 맞춘 뒤에 반영한다', () async {
    final container = await boot();
    final snapshot = Completer<List<TimerRead>>();
    repository.listActive = () => snapshot.future;

    await emit(const TimerWsConnected());
    await emit(_event(_timer('t2', TimerStatus.running, minute: 5)));
    // 이벤트보다 먼저 만든 목록이라 t2가 없다
    snapshot.complete([]);
    await pumpEventQueue();

    expect(active(container).map((t) => t.id), ['t2']);
  });

  test('명령 응답을 바로 반영하고, 그보다 이전 이벤트는 버린다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    repository.respond = (id, status) => _timer(id, status, minute: 3);
    final container = await boot();

    await container
        .read(timerControllerProvider.notifier)
        .pauseTimer(timerId: 't1');
    expect(active(container).single.status, TimerStatus.paused);

    await emit(_event(_timer('t1', TimerStatus.running, minute: 2)));
    expect(active(container).single.status, TimerStatus.paused);
  });

  test('이벤트는 가진 todo를 두고 상태·경과 시간만 바꾼다', () async {
    repository.listActive = () async => [
      _read('t1', TimerStatus.running, minute: 1),
    ];
    final container = await boot();

    await emit(
      _event(
        _timer(
          't1',
          TimerStatus.paused,
          minute: 2,
        ).copyWith(todoId: 'todo-1', elapsedTime: 90),
        action: 'pause',
      ),
    );

    final timer = active(container).single;
    expect(timer.status, TimerStatus.paused);
    expect(timer.elapsedTime, 90);
    expect(timer.todo, makeTodo());
    expect(repository.calls, isNot(contains('get:t1')));
  });

  test(
    '다른 클라이언트가 todo_id를 바꾼 timer.updated면 todo를 비우고 그 타이머를 다시 읽는다',
    () async {
      repository.listActive = () async => [
        _read('t1', TimerStatus.running, minute: 1),
      ];
      final reread = Completer<TimerRead>();
      repository.getOne = (_) => reread.future;
      final container = await boot();

      await emit(
        _event(
          _timer(
            't1',
            TimerStatus.running,
            minute: 2,
          ).copyWith(todoId: 'todo-2'),
        ),
      );
      expect(repository.calls, contains('get:t1'));
      expect(active(container).single.todo, isNull);

      reread.complete(
        _read('t1', TimerStatus.running, minute: 2, todoId: 'todo-2'),
      );
      await pumpEventQueue();
      expect(active(container).single.todo, makeTodo(id: 'todo-2'));
    },
  );

  test('action이 update인 이벤트는 링크가 같아도 그 타이머를 다시 읽는다', () async {
    // 태그만 바꾼 PATCH도 이 이벤트로 오는데 이벤트에는 태그가 없다
    repository.listActive = () async => [
      _read('t1', TimerStatus.running, minute: 1),
    ];
    repository.getOne = (id) async =>
        _read(id, TimerStatus.running, minute: 2).copyWith(tags: [makeTag()]);
    final container = await boot();

    await emit(
      _event(
        _timer('t1', TimerStatus.running, minute: 2).copyWith(todoId: 'todo-1'),
      ),
    );

    expect(repository.calls, contains('get:t1'));
    expect(active(container).single.tags, [makeTag()]);
  });

  test('연결 오류를 에러 배너 상태로 넘긴다', () async {
    final container = await boot();

    await emit(const TimerWsError(code: 'CONNECTION_ERROR', message: 'x'));

    expect(container.read(timerWsLastErrorProvider)?.code, 'CONNECTION_ERROR');
  });
}
