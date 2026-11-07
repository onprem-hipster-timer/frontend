import 'dart:async';

import 'package:fake_async/fake_async.dart';
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
int _seq = 0;

TimerRead _timer(String id, TimerStatus status, {required int minute}) =>
    makeTimer(
      id: id,
      status: status,
      startedAt: DateTime.utc(2026, 11, 6, 10),
    ).copyWith(updatedAt: DateTime.utc(2026, 11, 6, 10, minute));
TimerRead _read(String id, TimerStatus status, {required int minute}) => _timer(
  id,
  status,
  minute: minute,
).copyWith(todoId: 'todo-1', todo: makeTodo());
TimerRead _linked(String id, TimerStatus status, {required int minute}) =>
    _timer(id, status, minute: minute).copyWith(todoId: 'todo-1');
TimerWsTimerEvent _event(
  TimerRead timer, {
  String type = 'timer.updated',
  String action = 'update',
}) => TimerWsTimerEvent(
  id: 'm${_seq++}',
  type: type,
  fromUser: _me,
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

  ProviderContainer bootOn(FakeAsync async) {
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
    container.listen(myActiveTimersProvider, (_, _) {});
    async.elapse(Duration.zero);
    return container;
  }

  void emitOn(FakeAsync async, TimerWsEvent e) {
    client.events.add(e);
    async.elapse(Duration.zero);
  }

  int reads(String id) => repository.calls.where((c) => c == 'get:$id').length;
  TimerWsTimerEvent created() => _event(
    _linked('t1', TimerStatus.running, minute: 1),
    type: 'timer.created',
    action: 'start',
  );

  test('재시도를 기다리는 사이 재연결로 다시 맞춰 채워지면 다시 읽지 않는다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      emitOn(async, created());
      repository.listActive = () async => [
        _read('t1', TimerStatus.running, minute: 1),
      ];
      emitOn(async, const TimerWsConnected());
      async.elapse(const Duration(minutes: 1));
      expect(reads('t1'), 1);
      expect(
        container.read(myActiveTimersProvider).requireValue.single.todo,
        makeTodo(),
      );
    });
  });

  test('재시도를 기다리는 사이 재연결 목록에서 빠지면 다시 읽지 않는다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      emitOn(async, created());
      repository.listActive = () async => [];
      emitOn(async, const TimerWsConnected());
      async.elapse(const Duration(minutes: 1));
      expect(reads('t1'), 1);
      expect(container.read(myActiveTimersProvider).requireValue, isEmpty);
    });
  });

  test('재시도를 기다리는 사이 dispose되면 더 읽지 않고 예외도 없다', () {
    fakeAsync((async) {
      final container = bootOn(async);
      emitOn(async, created());
      async.elapse(const Duration(seconds: 1));
      container.dispose();
      async.elapse(const Duration(minutes: 1));
      expect(reads('t1'), 1);
    });
  });
}
