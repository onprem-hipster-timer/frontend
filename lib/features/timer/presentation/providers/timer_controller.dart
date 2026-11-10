import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';

part 'timer_controller.g.dart';

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

  TimerRead? _active() =>
      ref.read(activeTimerProvider).whenOrNull(data: (timer) => timer);

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
