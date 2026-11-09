import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/data/timer_repository_impl.dart';
import 'package:momeet/features/timer/domain/timer_ledger.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/providers/api_providers.dart';

part 'timer_providers.g.dart';

// ============================================================
// Timer WebSocket Client
// ============================================================

/// 타이머 WebSocket 클라이언트 (수신 전용)
///
/// 로그인된 경우에만 non-null. JWT가 아니라 사용자 ID를 지켜보므로, JWT가 갱신될 때마다
/// 소켓을 다시 열지 않는다. 클라이언트가 (재)연결할 때마다 최신 JWT를 받아 쓴다.
/// 앱이 포그라운드로 돌아오면 끊긴 연결을 백오프를 기다리지 않고 다시 연다.
final timerWsClientProvider = Provider<TimerWsClient?>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return null;

  final auth = ref.read(authProvider.notifier);
  final client = TimerWsClient(
    accessToken: auth.freshAccessToken,
    refreshAccessToken: auth.refreshAccessToken,
  );
  final lifecycle = AppLifecycleListener(onResume: client.reconnectNow);
  ref.onDispose(() {
    lifecycle.dispose();
    client.dispose();
  });

  return client;
});

// ============================================================
// Timer Repository
// ============================================================

/// 타이머 리포지토리 프로바이더
///
/// REST API 클라이언트를 래핑하여 도메인 레이어 인터페이스를 제공합니다.
final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  final client = ref.watch(timersApiProvider);
  return TimerRepositoryImpl(client, ref.watch(visibilityApiProvider));
});

// ============================================================
// Timer Data Providers
// ============================================================

/// 마지막 WebSocket 에러 (연결 오류·인증 실패 시 설정, UI에서 에러 배너로 표시. 닫거나 다시 연결되면 초기화)
class TimerWsLastErrorNotifier extends Notifier<TimerWsError?> {
  @override
  TimerWsError? build() => null;

  void setError(TimerWsError? error) => state = error;
}

final timerWsLastErrorProvider =
    NotifierProvider<TimerWsLastErrorNotifier, TimerWsError?>(
      TimerWsLastErrorNotifier.new,
    );

/// 친구 타이머 활동 알림 스트림 (`from_user`가 내가 아닌 이벤트)
///
/// 타이머 화면에서 SnackBar를 띄우기 위한 UI-scoped 스트림.
/// 화면을 벗어나 listener가 모두 사라지면 WS 구독을 정리하도록 autoDispose.
final timerFriendActivityProvider =
    StreamProvider.autoDispose<TimerWsTimerEvent>((ref) async* {
      final myId = ref.watch(currentUserProvider.select((user) => user?.id));
      final client = ref.watch(timerWsClientProvider);
      if (client == null) return;

      await for (final event in client.messageStream) {
        if (event is TimerWsTimerEvent && event.fromUser != myId) {
          yield event;
        }
      }
    });

/// 타이머 목록에 REST 목록보다 먼저 보일 타이머 (명령 응답 전 값과 받은 응답)
///
/// 목록은 명령 뒤에 REST로 다시 읽으므로 그 사이 [timerView]로 이 값을 겹쳐 보인다.
class TimerViewsNotifier extends Notifier<Map<String, TimerRead>> {
  @override
  Map<String, TimerRead> build() => const {};

  void show(TimerRead timer) => state = {...state, timer.id: timer};

  void drop(String timerId) => state = {...state}..remove(timerId);
}

final timerViewsProvider =
    NotifierProvider<TimerViewsNotifier, Map<String, TimerRead>>(
      TimerViewsNotifier.new,
    );

/// 목록의 [listed] 대신 보일 타이머. 목록 값이 [views]의 값보다 나중([isLaterTimer])이면 목록 값
TimerRead timerView(Map<String, TimerRead> views, TimerRead listed) {
  final view = views[listed.id];
  return view != null && !isLaterTimer(listed, view) ? view : listed;
}

/// 내 활성(RUNNING·PAUSED) 타이머. 최근에 시작한 순
///
/// REST 조회, 내 실시간 이벤트(`from_user`가 나), 명령 응답을 [TimerLedger] 규칙으로 반영한다.
/// 이벤트로 관계 필드(일정·Todo 등)가 비면 그 타이머를 REST로 다시 읽어 채운다.
/// 소켓이 (재)연결될 때마다 REST로 다시 맞추고, 맞추는 동안 들어온 반영은 맞춘 뒤에 한다.
/// 로그인한 사용자가 바뀌면 가진 타이머를 버리고 새 사용자의 목록으로 다시 맞춘다.
///
/// 테스트: test/features/timer/presentation/providers/my_active_timers_test.dart
@riverpod
class MyActiveTimers extends _$MyActiveTimers {
  var _ledger = TimerLedger();
  String? _userId;

  /// REST로 다시 맞추는 중에 들어온 반영. 맞추는 중이 아니면 null
  List<void Function()>? _deferred;
  Future<void>? _resyncing;
  bool _resyncAgain = false;

  @override
  Future<List<TimerRead>> build() async {
    final myId = ref.watch(currentUserProvider.select((user) => user?.id));
    if (myId != _userId) {
      _userId = myId;
      _ledger = TimerLedger();
      _deferred?.clear();
    }
    final client = ref.watch(timerWsClientProvider);
    final subscription = client?.messageStream.listen(
      (event) => _onEvent(event, myId),
    );
    ref.onDispose(() => subscription?.cancel());

    await _resync();
    return _ledger.active;
  }

  /// REST 응답을 반영한다. [ownCommand]면 이 클라이언트가 보낸 명령의 응답이다 ([TimerLedger.apply])
  void apply(TimerRead timer, {bool ownCommand = false}) =>
      _change(() => _ledger.apply(timer, ownCommand: ownCommand));

  /// 가진 [timerId] 타이머. 없으면 null
  TimerRead? timer(String timerId) => _ledger[timerId];

  /// 명령 응답 전에 [timer]를 먼저 보인다. 응답·이벤트가 덮는다 ([TimerLedger.showPending])
  void showPending(TimerRead timer) {
    _ledger.showPending(timer);
    state = AsyncData(_ledger.active);
  }

  /// 명령이 실패하면 [pending]을 [previous]로 되돌린다 ([TimerLedger.revertPending])
  void revertPending(TimerRead pending, TimerRead previous) {
    _ledger.revertPending(pending, previous);
    state = AsyncData(_ledger.active);
  }

  /// Todo를 바꾼 REST 응답 [todo]를 그 Todo에 연결된 타이머에 반영한다.
  ///
  /// 타이머가 바뀐 것이 아니라 타이머 목록은 다시 읽지 않는다.
  void updateTodo(TodoRead todo) {
    _ledger.updateTodo(todo);
    state = AsyncData(_ledger.active);
  }

  void _onEvent(TimerWsEvent event, String? myId) {
    switch (event) {
      case TimerWsConnected():
        ref.read(timerWsLastErrorProvider.notifier).setError(null);
        _resync().then((_) {
          if (ref.mounted) _publish();
        });
      case TimerWsTimerEvent(:final payload, :final fromUser)
          when fromUser == myId:
        _change(() {
          final timer = payload.timer;
          if (timer == null) {
            _ledger.delete(payload.timerId!);
          } else if (_ledger.applyPartial(
            timer,
            // 태그만 바꾼 PATCH도 이 action으로 오는데 이벤트에는 태그가 없다
            relationsChanged: payload.action == 'update',
          )) {
            _read(timer.id);
          }
        });
      case TimerWsError():
        ref.read(timerWsLastErrorProvider.notifier).setError(event);
    }
  }

  /// 다시 읽기가 실패했을 때 다시 읽기 전에 기다리는 시간. 다 실패하면 다음 이벤트나 재연결까지 둔다
  static const _readRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  /// [timerId]를 관계를 포함해 다시 읽어 반영한다.
  ///
  /// 실패하면 가진 타이머를 그대로 두고 [_readRetryDelays]만큼 기다렸다 다시 읽는다.
  /// 기다리는 사이 다른 REST 응답으로 채워졌거나 타이머가 빠졌으면 다시 읽지 않는다.
  /// 다시 읽은 todo가 가진 todo와 다르면 다른 곳에서 Todo가 바뀐 것이라 Todo 목록도 다시 읽게 한다.
  Future<void> _read(String timerId) async {
    for (var attempt = 0; ; attempt++) {
      try {
        final timer = await ref.read(timerRepositoryProvider).getTimer(timerId);
        if (!ref.mounted) return;
        final held = _ledger[timerId]?.todo;
        if (held != null && held != timer.todo) ref.invalidate(todosProvider);
        apply(timer);
        return;
      } catch (error) {
        debugPrint('타이머 조회 실패: $error');
        if (attempt == _readRetryDelays.length) return;
      }
      await Future<void>.delayed(_readRetryDelays[attempt]);
      if (!ref.mounted || !_ledger.needsRead(timerId)) return;
    }
  }

  void _change(void Function() change) {
    final deferred = _deferred;
    if (deferred != null) {
      deferred.add(change);
      return;
    }
    change();
    _publish();
  }

  void _publish() {
    state = AsyncData(_ledger.active);
    ref.invalidate(timerHistoryProvider);
  }

  /// REST로 다시 맞춘다. 맞추는 중에 또 불리면 끝난 뒤 한 번 더 맞춘다.
  Future<void> _resync() {
    if (_resyncing != null) {
      _resyncAgain = true;
      return _resyncing!;
    }
    return _resyncing = _runResync();
  }

  Future<void> _runResync() async {
    _deferred = [];
    do {
      _resyncAgain = false;
      final ledger = _ledger;
      try {
        final active = await ref
            .read(timerRepositoryProvider)
            .listTimers(
              status: [TimerStatus.running.json!, TimerStatus.paused.json!],
            );
        if (!ref.mounted) return;
        // 받는 사이 사용자가 바뀌었으면 이전 사용자의 목록이다
        if (identical(ledger, _ledger)) _ledger.resync(active);
      } catch (error) {
        debugPrint('활성 타이머 조회 실패: $error');
      }
    } while (_resyncAgain && ref.mounted);

    final deferred = _deferred!;
    _deferred = null;
    _resyncing = null;
    for (final change in deferred) {
      change();
    }
  }
}

/// 대시보드에서 고른 내 활성 타이머 id. 고르지 않았으면 null
///
/// 좁은 화면과 넓은 화면이 같은 값을 쓰도록 위젯 상태가 아니라 여기에 둔다.
@riverpod
class FocusedTimerId extends _$FocusedTimerId {
  @override
  String? build() => null;

  void focus(String? timerId) => state = timerId;
}

/// [timers](최근에 시작한 순) 중 대시보드가 보일 타이머
///
/// [focusedId] 타이머가 있으면 그것, 없으면(고르지 않았거나 끝났으면) 가장 최근에 시작한 실행 중 타이머,
/// 실행 중인 타이머가 없으면 가장 최근에 시작한 타이머다.
TimerRead? focusedTimer(List<TimerRead> timers, String? focusedId) =>
    timers.where((timer) => timer.id == focusedId).firstOrNull ??
    timers.where((timer) => timer.status == TimerStatus.running).firstOrNull ??
    timers.firstOrNull;

/// 활성 타이머 (대시보드가 보이는 타이머, [focusedTimer]). 타이머 명령에 id를 주지 않으면 이 타이머에 보낸다
///
/// 테스트: test/features/timer/presentation/providers/focused_timer_test.dart
@riverpod
AsyncValue<TimerRead?> activeTimer(Ref ref) {
  final focusedId = ref.watch(focusedTimerIdProvider);
  return ref
      .watch(myActiveTimersProvider)
      .whenData((timers) => focusedTimer(timers, focusedId));
}

/// 타이머 히스토리 조회
///
/// RUNNING·PAUSED·COMPLETED 타이머를 모두 조회합니다.
/// 활성(RUNNING/PAUSED)이 상단, 완료(COMPLETED)가 하단 — 각 그룹 내에서 최신순.
@riverpod
Future<List<TimerRead>> timerHistory(Ref ref) async {
  final repository = ref.watch(timerRepositoryProvider);

  try {
    final timers = await repository.getTimerHistory();
    return sortTimerHistory(timers);
  } catch (error) {
    debugPrint('타이머 히스토리 조회 실패: $error');
    throw Exception('타이머 히스토리를 불러올 수 없습니다: $error');
  }
}

/// 친구의 타이머 이벤트가 이만큼 더 오지 않으면 [sharedTimersProvider]를 다시 읽는다
const sharedTimersRefetchDelay = Duration(milliseconds: 500);

/// 다른 사용자가 나에게 공유한 타이머. 최근에 시작한 순
///
/// 친구의 타이머 이벤트([timerFriendActivityProvider])가 오면 마지막 이벤트 뒤
/// [sharedTimersRefetchDelay]를 기다려 한 번 다시 읽는다.
///
/// 테스트: test/features/timer/presentation/providers/shared_timers_test.dart
@riverpod
Future<List<TimerRead>> sharedTimers(Ref ref) async {
  Timer? refetch;
  ref.onDispose(() => refetch?.cancel());
  ref.listen(timerFriendActivityProvider, (_, next) {
    if (next is! AsyncData) return;
    refetch?.cancel();
    refetch = Timer(sharedTimersRefetchDelay, ref.invalidateSelf);
  });
  final timers = await ref.watch(timerRepositoryProvider).listSharedTimers();
  return [...timers]..sort(
    (a, b) =>
        (b.startedAt ?? b.createdAt).compareTo(a.startedAt ?? a.createdAt),
  );
}

/// 서버 기준 현재 시각([serverClockProvider])을 바로 한 번, 이후 1초마다 낸다
@riverpod
Stream<DateTime> serverNow(Ref ref) async* {
  final clock = ref.watch(serverClockProvider);
  yield clock.now();
  // yield*는 구독을 취소하면 바로 틱을 멈춘다
  yield* Stream.periodic(const Duration(seconds: 1), (_) => clock.now());
}

// ============================================================
// Timer Ticker Provider (Local UI Ticker)
// ============================================================

/// 활성 타이머의 표시 남은 시간 ([displayRemaining], 서버 시각 기준)을 1초마다 갱신. 활성 타이머가 없으면 Duration.zero
@riverpod
Stream<Duration> timerTicker(Ref ref) async* {
  final activeTimerAsync = ref.watch(activeTimerProvider);
  final clock = ref.watch(serverClockProvider);

  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    final activeTimer = activeTimerAsync.when(
      data: (timer) => timer,
      loading: () => null,
      error: (error, stack) => null,
    );

    yield activeTimer == null
        ? Duration.zero
        : displayRemaining(activeTimer, clock.now());
  }
}

// ============================================================
// Timer Controller (Mutation)
// ============================================================

/// 새 타이머의 기본 집중 시간 (`allocated_duration`)
const defaultFocusDuration = Duration(minutes: 25);

/// 타이머 제어 로직
///
/// 타이머 시작/정지 등의 명령을 REST로 보내고, 응답을 [MyActiveTimers]에 반영한다.
/// 같은 변경이 실시간 이벤트로도 들어오지만 `updated_at` 규칙으로 한 번만 반영된다.
@riverpod
class TimerController extends _$TimerController {
  @override
  FutureOr<void> build() {}

  void _apply(TimerRead timer) {
    if (ref.exists(myActiveTimersProvider)) {
      ref.read(myActiveTimersProvider.notifier).apply(timer, ownCommand: true);
    }
    ref.invalidate(timerHistoryProvider);
    // 연결된 타이머가 끝나면 서버가 그 Todo를 완료·취소로 바꾼다
    if (timer.todoId != null &&
        (timer.status == TimerStatus.completed ||
            timer.status == TimerStatus.cancelled)) {
      ref.invalidate(todosProvider);
    }
  }

  /// 타이머 시작. 시작한 타이머를 대시보드가 보이게 고른다
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _create(
        TimerCreate(
          todoId: relatedTodoId,
          scheduleId: scheduleId,
          title: title ?? '새 작업',
          allocatedDuration:
              allocatedDurationSeconds ?? defaultFocusDuration.inSeconds,
        ),
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// [todos]마다 [duration] 길이의 타이머를 그 할 일의 제목으로 연결해 하나씩 시작한다
  ///
  /// 차례대로 보내고, 실패한 할 일이 있어도 나머지를 보내며 시작한 타이머는 그대로 둔다.
  /// 시작하지 못한 할 일을 [todos] 순서대로 돌려준다. 마지막으로 시작한 타이머를 대시보드가 보이게 고른다.
  Future<List<TodoRead>> startTimers({
    required List<TodoRead> todos,
    required Duration duration,
  }) async {
    state = const AsyncValue.loading();
    final failed = <TodoRead>[];
    for (final todo in todos) {
      try {
        await _create(
          TimerCreate(
            todoId: todo.id,
            title: todo.title,
            allocatedDuration: duration.inSeconds,
          ),
        );
      } catch (error) {
        debugPrint('타이머 시작 실패 (${todo.id}): $error');
        failed.add(todo);
      }
    }
    state = const AsyncValue.data(null);
    return failed;
  }

  /// [data]로 타이머를 만들어 반영하고 대시보드가 보이게 고른다
  Future<void> _create(TimerCreate data) async {
    final timer = await ref.read(timerRepositoryProvider).createTimer(data);
    _apply(timer);
    ref.read(focusedTimerIdProvider.notifier).focus(timer.id);
  }

  /// 타이머 정지
  ///
  /// [timerId]를 주면 해당 타이머를 정지하고, 생략 시 활성 타이머를 정지합니다.
  /// 되돌릴 수 없는 명령이라 응답을 받은 뒤에 반영하고, 정지 응답을 받아야 끝납니다.
  /// 같은 타이머의 명령이 응답을 기다리는 중이면 그 응답(실패도)을 기다렸다 보냅니다.
  /// 정지를 기다리는 같은 타이머의 정지는 따로 보내지 않고 그 결과를 함께 받습니다.
  Future<void> stopTimer({String? timerId}) async {
    final id = timerId ?? _active()?.id;
    if (id == null) {
      final error = Exception('정지할 활성 타이머가 없습니다');
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
    await (_stopping[id] ??= _stop(id).whenComplete(() {
      _stopping.remove(id);
    }));
  }

  Future<void> _stop(String timerId) async {
    while (_inFlight.containsKey(timerId)) {
      await _inFlight[timerId];
    }
    await _command(
      timerId,
      send: (repository) => repository.stopTimer(timerId),
    );
  }

  /// 타이머 일시정지
  ///
  /// [timerId]를 주면 해당 타이머를 일시정지하고, 생략 시 활성 타이머를 일시정지합니다.
  /// 응답 전에 서버 시각 기준 경과 시간으로 멈춘 타이머를 먼저 보입니다.
  Future<void> pauseTimer({String? timerId}) async {
    final active = _active();
    final id = timerId ?? active?.id;
    if (id == null ||
        (timerId == null && active?.status != TimerStatus.running)) {
      final error = Exception('일시정지할 실행 중인 타이머가 없습니다');
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
    await _command(
      id,
      show: (timer, now) => timer.copyWith(
        status: TimerStatus.paused,
        elapsedTime: displayElapsed(timer, now).inSeconds,
        pausedAt: now,
      ),
      send: (repository) => repository.pauseTimer(id),
    );
  }

  /// 타이머 재개
  ///
  /// [timerId]를 주면 해당 타이머를 재개하고, 생략 시 활성 타이머를 재개합니다.
  /// 응답 전에 지금부터 다시 세는 타이머를 먼저 보입니다.
  Future<void> resumeTimer({String? timerId}) async {
    final active = _active();
    final id = timerId ?? active?.id;
    if (id == null ||
        (timerId == null && active?.status != TimerStatus.paused)) {
      final error = Exception('재개할 일시정지된 타이머가 없습니다');
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
    await _command(
      id,
      show: (timer, now) =>
          timer.copyWith(status: TimerStatus.running, startedAt: now),
      send: (repository) => repository.resumeTimer(id),
    );
  }

  /// 타이머 연장
  ///
  /// [timerId]를 주면 해당 타이머를, 생략 시 활성 타이머를 [by]만큼 늘린 뒤(`PATCH allocated_duration`) 재개합니다.
  /// 늘리기에 실패하거나 응답이 PAUSED가 아니면(이미 실행 중), 늘리는 사이 정지를 요청했으면 재개하지 않습니다.
  Future<void> extendTimer({String? timerId, required Duration by}) async {
    final active = _active();
    final timer = timerId == null || timerId == active?.id
        ? active
        : ref.exists(myActiveTimersProvider)
        ? ref.read(myActiveTimersProvider.notifier).timer(timerId)
        : null;
    if (timer == null) {
      final error = Exception('연장할 타이머가 없습니다');
      state = AsyncValue.error(error, StackTrace.current);
      throw error;
    }
    final id = timer.id;
    final extended = await _command(
      id,
      send: (repository) => repository.updateTimer(
        id,
        TimerUpdate(allocatedDuration: timer.allocatedDuration + by.inSeconds),
      ),
    );
    if (extended?.status != TimerStatus.paused || _stopping.containsKey(id)) {
      return;
    }
    await resumeTimer(timerId: id);
  }

  TimerRead? _active() => ref
      .read(activeTimerProvider)
      .when(data: (timer) => timer, loading: () => null, error: (_, _) => null);

  /// 타이머 ID별 응답을 기다리는 명령. 응답·실패를 받으면 끝난다. 같은 타이머에 겹친 명령은 보내지 않는다
  final _inFlight = <String, Future<void>>{};

  /// 타이머 ID별 요청한 정지. 정지를 기다리는 동안 연장은 재개하지 않는다
  final _stopping = <String, Future<void>>{};

  /// [timerId]에 명령을 보낸다.
  ///
  /// [show]가 있고 그 타이머를 가졌으면 응답 전에 [show]의 값을 활성 타이머와 목록에 먼저 보이고,
  /// 실패하면 되돌린다. 응답을 기다리는 동안 로딩 상태로 두지 않는다.
  /// 반영한 응답을 돌려주고, 같은 타이머의 명령이 응답을 기다리는 중이면 보내지 않고 null을 돌려준다.
  Future<TimerRead?> _command(
    String timerId, {
    TimerRead Function(TimerRead timer, DateTime now)? show,
    required Future<TimerRead> Function(TimerRepository repository) send,
  }) async {
    if (_inFlight.containsKey(timerId)) return null;
    final answered = Completer<void>();
    _inFlight[timerId] = answered.future;
    final timers = ref.exists(myActiveTimersProvider)
        ? ref.read(myActiveTimersProvider.notifier)
        : null;
    final views = ref.read(timerViewsProvider.notifier);
    final held = timers?.timer(timerId);
    final shown = held == null || show == null
        ? null
        : show(held, ref.read(serverClockProvider).now());
    if (shown != null) {
      timers!.showPending(shown);
      views.show(shown);
    }

    try {
      final timer = await send(ref.read(timerRepositoryProvider));
      _apply(timer);
      views.show(timer);
      state = const AsyncValue.data(null);
      return timer;
    } catch (error, stackTrace) {
      if (shown != null) {
        timers!.revertPending(shown, held!);
        views.drop(timerId);
      }
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } finally {
      _inFlight.remove(timerId);
      answered.complete();
    }
  }
}

// ============================================================
// Timer History Sorting (순수 함수 — 테스트 용이)
// ============================================================

/// 타이머 히스토리를 정렬합니다.
///
/// 활성(RUNNING/PAUSED)이 상단, 완료(COMPLETED 등)가 하단 — 각 그룹 내 최신순.
List<TimerRead> sortTimerHistory(List<TimerRead> timers) {
  final sorted = List<TimerRead>.from(timers);
  sorted.sort((a, b) {
    final aActive =
        a.status == TimerStatus.running || a.status == TimerStatus.paused;
    final bActive =
        b.status == TimerStatus.running || b.status == TimerStatus.paused;
    if (aActive != bActive) return aActive ? -1 : 1;

    final aStarted = a.startedAt ?? a.createdAt;
    final bStarted = b.startedAt ?? b.createdAt;
    return bStarted.compareTo(aStarted);
  });
  return sorted;
}

// ============================================================
// Utility Functions
// ============================================================

/// DateTime을 MM/DD 형식으로 변환 (날짜 표시용)
String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.month.toString().padLeft(2, '0')}/'
      '${local.day.toString().padLeft(2, '0')}';
}

/// 두 DateTime 객체가 같은 날인지 확인
bool isSameDay(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();

  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}
