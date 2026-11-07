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
import '../../../../helpers/timer_fixtures.dart';

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
TimerRead _read(String id, TimerStatus status, {required int minute}) => _timer(
  id,
  status,
  minute: minute,
).copyWith(todoId: 'todo-1', todo: makeTodo());

/// Todo에 연결된 타이머의 이벤트 payload (관계 필드 없음)
TimerRead _linked(String id, TimerStatus status, {required int minute}) =>
    _timer(id, status, minute: minute).copyWith(todoId: 'todo-1');

int _seq = 0;

TimerWsTimerEvent _event(
  TimerRead timer, {
  String type = 'timer.updated',
  String action = 'update',
  String fromUser = _me,
}) => TimerWsTimerEvent(
  id: 'm${_seq++}',
  type: type,
  fromUser: fromUser,
  timestamp: timer.updatedAt,
  payload: TimerWsEventPayload(action: action, timer: timer),
);

TimerWsTimerEvent _deleted(String timerId, {String fromUser = _me}) =>
    TimerWsTimerEvent(
      id: 'm${_seq++}',
      type: 'timer.deleted',
      fromUser: fromUser,
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

  test('내 timer.created 이벤트로 새 타이머가 활성에 들어온다', () async {
    final container = await boot();

    await emit(
      _event(
        _timer('t1', TimerStatus.running, minute: 1),
        type: 'timer.created',
        action: 'start',
      ),
    );

    expect(active(container).single.id, 't1');
    expect(container.read(activeTimerProvider).value?.id, 't1');
  });

  test('처음 보는 타이머의 이벤트(다른 기기의 timer.created)면 다시 읽어 관계 필드를 채운다', () async {
    repository.getOne = (id) async => _read(id, TimerStatus.running, minute: 1);
    final container = await boot();

    await emit(
      _event(
        _linked('t1', TimerStatus.running, minute: 1),
        type: 'timer.created',
        action: 'start',
      ),
    );

    expect(repository.calls, contains('get:t1'));
    expect(active(container).single.todo, makeTodo());
  });

  test('다시 읽는 사이 더 나중 이벤트가 오면 이전 시각의 다시 읽은 결과는 버리고 한 번 더 읽는다', () async {
    final first = Completer<TimerRead>();
    final second = Completer<TimerRead>();
    var call = 0;
    repository.getOne = (_) => ++call == 1 ? first.future : second.future;
    final container = await boot();

    await emit(
      _event(
        _linked('t1', TimerStatus.running, minute: 1),
        type: 'timer.created',
        action: 'start',
      ),
    );
    await emit(
      _event(_linked('t1', TimerStatus.paused, minute: 3), action: 'pause'),
    );
    first.complete(_read('t1', TimerStatus.running, minute: 2));
    await pumpEventQueue();

    expect(active(container).single.status, TimerStatus.paused);
    expect(active(container).single.todo, isNull);

    second.complete(_read('t1', TimerStatus.paused, minute: 3));
    await pumpEventQueue();

    expect(repository.calls.where((c) => c == 'get:t1'), hasLength(2));
    expect(active(container).single.todo, makeTodo());
  });

  test('다시 읽기가 실패하면 이벤트로 받은 타이머를 그대로 둔다', () async {
    repository.listActive = () async => [
      _read('t1', TimerStatus.running, minute: 1),
    ];
    repository.getOne = (_) async => throw Exception('500');
    final container = await boot();

    await emit(
      _event(
        _timer('t1', TimerStatus.paused, minute: 2).copyWith(todoId: 'todo-2'),
      ),
    );

    final timer = active(container).single;
    expect(repository.calls, contains('get:t1'));
    expect(timer.status, TimerStatus.paused);
    expect(timer.todoId, 'todo-2');
    expect(timer.todo, isNull);
  });

  test('내 타이머가 끝났다는 이벤트가 오면 활성에서 빠진다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    final container = await boot();

    await emit(
      _event(_timer('t1', TimerStatus.completed, minute: 2), action: 'stop'),
    );

    expect(active(container), isEmpty);
    expect(container.read(activeTimerProvider).value, isNull);
  });

  test('친구가 보낸 timer.deleted는 내 타이머를 지우지 않는다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    final container = await boot();

    await emit(_deleted('t1', fromUser: 'friend'));

    expect(active(container).single.id, 't1');
  });

  test('다시 맞추는 중에 connected가 또 오면 목록을 한 번 더 받고 마지막 결과로 끝난다', () async {
    final container = await boot();
    final first = Completer<List<TimerRead>>();
    final second = Completer<List<TimerRead>>();
    var call = 0;
    repository.listActive = () => ++call == 1 ? first.future : second.future;

    await emit(const TimerWsConnected());
    await emit(const TimerWsConnected());
    first.complete([_timer('t1', TimerStatus.running, minute: 1)]);
    await pumpEventQueue();
    second.complete([_timer('t2', TimerStatus.paused, minute: 2)]);
    await pumpEventQueue();

    expect(repository.calls.where((c) => c == 'list'), hasLength(3));
    expect(active(container).map((t) => t.id), ['t2']);
  });

  test('다시 맞추기가 실패해도 가진 상태를 유지하고 그 뒤 이벤트를 반영한다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    final container = await boot();

    repository.listActive = () async => throw Exception('500');
    await emit(const TimerWsConnected());
    await emit(_event(_timer('t1', TimerStatus.paused, minute: 2)));

    expect(active(container).single.status, TimerStatus.paused);
  });

  test('다시 연결되면 에러 배너 상태를 지운다', () async {
    final container = await boot();

    await emit(const TimerWsError(code: 'CONNECTION_ERROR', message: 'x'));
    expect(container.read(timerWsLastErrorProvider), isNotNull);

    await emit(const TimerWsConnected());
    expect(container.read(timerWsLastErrorProvider), isNull);
  });

  test('명령 응답으로 끝난 타이머는 활성에서 빠진다', () async {
    repository.listActive = () async => [
      _timer('t1', TimerStatus.running, minute: 1),
    ];
    repository.respond = (id, status) => _timer(id, status, minute: 3);
    final container = await boot();

    await container
        .read(timerControllerProvider.notifier)
        .stopTimer(timerId: 't1');

    expect(active(container), isEmpty);
    expect(container.read(activeTimerProvider).value, isNull);
  });
}
