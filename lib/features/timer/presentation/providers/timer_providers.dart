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

import 'package:momeet/features/timer/presentation/utils/timer_history_format.dart';

export 'package:momeet/features/timer/presentation/providers/timer_controller.dart';
export 'package:momeet/features/timer/presentation/utils/timer_history_format.dart';

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

  final timers = await repository.getTimerHistory();
  return sortTimerHistory(timers);
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
    final activeTimer = activeTimerAsync.whenOrNull(data: (timer) => timer);

    yield activeTimer == null
        ? Duration.zero
        : displayRemaining(activeTimer, clock.now());
  }
}
