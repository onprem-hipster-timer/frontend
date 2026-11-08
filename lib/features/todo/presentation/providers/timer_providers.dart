import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/network/timer_request.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart'
    as timer_feature;
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';

part 'timer_providers.g.dart';

// ============================================================
// Timer Data Provider
// ============================================================

/// 타이머 목록 조회
@riverpod
Future<List<TimerRead>> timers(
  Ref ref, {
  List<String>? status,
  String? type,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final api = ref.watch(timersApiProvider);

  try {
    final response = await api.listTimersV1TimersGet(
      status: status,
      type: type,
      startDate: startDate,
      endDate: endDate,
      includeTodo: true, // Todo 정보 포함
      includeSchedule: true, // Schedule 정보 포함
      options: timerRequest(),
    );

    return response;
  } catch (error) {
    throw Exception('타이머 조회 실패: $error');
  }
}

/// 활성 타이머 (RUNNING, PAUSED 상태). 실시간 이벤트가 반영된 [timer_feature.myActiveTimersProvider]를 쓴다
@riverpod
Future<List<TimerRead>> activeTimers(Ref ref) =>
    ref.watch(timer_feature.myActiveTimersProvider.future);

/// Todo별 타이머 집계 데이터
///
/// 끝난(COMPLETED) 타이머의 경과 시간만 더한다. 활성 타이머는 [activeTimerStreamProvider]로 따로 센다.
/// 활성 타이머가 끝나 활성 목록에서 빠지면 타이머 목록을 다시 읽는다.
///
/// 테스트: test/features/todo/presentation/providers/todo_timer_aggregation_test.dart
@riverpod
Future<Map<String, TodoTimerAggregation>> todoTimerAggregations(Ref ref) async {
  ref.listen(activeTimersProvider, (previous, next) {
    final before = {...?previous?.value?.map((timer) => timer.id)};
    final after = {...?next.value?.map((timer) => timer.id)};
    if (before.difference(after).isNotEmpty) ref.invalidate(timersProvider);
  });
  final timers = await ref.watch(timersProvider().future);
  final todoTree = await ref.watch(allTodoTreeProvider.future);

  return _aggregateTimersByTodo(timers, todoTree);
}

/// 특정 Todo의 타이머 집계 (하위 Todo 포함)
@riverpod
Future<TodoTimerAggregation?> todoTimerAggregation(
  Ref ref,
  String todoId,
) async {
  final aggregations = await ref.watch(todoTimerAggregationsProvider.future);
  return aggregations[todoId];
}

// ============================================================
// Active Timer Stream Provider (1초마다 갱신)
// ============================================================

/// 활성 타이머 실시간 스트림
///
/// 구독하자마자 한 번 내고 이후 1초마다 냅니다. [activeTimersProvider]가 바뀌면 스트림이 재시작됩니다.
@riverpod
Stream<Map<String, ActiveTimerState>> activeTimerStream(Ref ref) async* {
  final activeTimers = await ref.watch(activeTimersProvider.future);
  final clock = ref.watch(serverClockProvider);

  Map<String, ActiveTimerState> states() {
    final now = clock.now();
    final activeStates = <String, ActiveTimerState>{};

    for (final timer in activeTimers) {
      if (timer.status != TimerStatus.running &&
          timer.status != TimerStatus.paused) {
        continue;
      }
      activeStates[timer.todoId ??
          timer.scheduleId ??
          timer.id] = ActiveTimerState(
        timerId: timer.id,
        elapsedSeconds: displayElapsed(timer, now).inSeconds,
        remainingSeconds: displayRemaining(timer, now).inSeconds,
        status: timer.status,
        startedAt: timer.startedAt,
        pausedAt: timer.pausedAt,
      );
    }

    return activeStates;
  }

  yield states();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => states());
}

// ============================================================
// Helper Classes & Functions
// ============================================================

/// Todo별 타이머 집계 데이터
class TodoTimerAggregation {
  final String todoId;
  final int totalElapsedSeconds; // 본인 + 하위 Todo의 끝난 타이머 총 시간
  final int ownElapsedSeconds; // 본인의 끝난 타이머 시간
  final List<TimerRead> timers; // 연결된 타이머들
  final bool hasActiveTimer; // 활성 타이머 여부
  final String? activeTimerId; // 활성 타이머 ID

  const TodoTimerAggregation({
    required this.todoId,
    required this.totalElapsedSeconds,
    required this.ownElapsedSeconds,
    required this.timers,
    required this.hasActiveTimer,
    this.activeTimerId,
  });

  /// 총 시간을 HH:MM:SS 형태로 포맷
  String get totalTimeFormatted => _formatDuration(totalElapsedSeconds);

  /// 본인 시간을 HH:MM:SS 형태로 포맷
  String get ownTimeFormatted => _formatDuration(ownElapsedSeconds);

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// 활성 타이머 상태
class ActiveTimerState {
  final String timerId;
  final int elapsedSeconds;

  /// 표시 남은 시간 (초, [displayRemaining])
  final int remainingSeconds;
  final TimerStatus status;
  final DateTime? startedAt;
  final DateTime? pausedAt;

  const ActiveTimerState({
    required this.timerId,
    required this.elapsedSeconds,
    this.remainingSeconds = 0,
    required this.status,
    this.startedAt,
    this.pausedAt,
  });

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;

  /// 경과 시간을 HH:MM:SS 형태로 포맷
  String get formattedTime =>
      TodoTimerAggregation._formatDuration(elapsedSeconds);
}

/// Todo별 타이머 집계 로직
Map<String, TodoTimerAggregation> _aggregateTimersByTodo(
  List<TimerRead> timers,
  TodoTree todoTree,
) {
  final aggregations = <String, TodoTimerAggregation>{};

  // 1. 각 Todo의 직접 연결된 타이머 집계
  final todoTimers = <String, List<TimerRead>>{};
  final todoOwnTime = <String, int>{};
  final activeTimers = <String, String>{};

  for (final timer in timers) {
    if (timer.todoId != null) {
      todoTimers.putIfAbsent(timer.todoId!, () => []).add(timer);
      if (timer.status == TimerStatus.completed) {
        todoOwnTime[timer.todoId!] =
            (todoOwnTime[timer.todoId!] ?? 0) + timer.elapsedTime;
      }

      if (timer.status == TimerStatus.running ||
          timer.status == TimerStatus.paused) {
        activeTimers[timer.todoId!] = timer.id;
      }
    }
  }

  // 2. 각 Todo의 하위 Todo 시간 재귀 집계
  final todoTotalTime = <String, int>{...todoOwnTime};

  void calculateTotalTime(TodoTreeNode node) {
    int total = todoOwnTime[node.id] ?? 0;

    // 하위 Todo들의 시간 합산
    for (final child in node.children) {
      calculateTotalTime(child); // 재귀 호출
      total += todoTotalTime[child.id] ?? 0;
    }

    todoTotalTime[node.id] = total;
  }

  // 루트부터 시작해서 모든 Todo의 총 시간 계산
  for (final rootNode in todoTree.roots) {
    calculateTotalTime(rootNode);
  }

  // 3. TodoTimerAggregation 객체 생성
  for (final todoId in todoTree.nodeMap.keys) {
    aggregations[todoId] = TodoTimerAggregation(
      todoId: todoId,
      totalElapsedSeconds: todoTotalTime[todoId] ?? 0,
      ownElapsedSeconds: todoOwnTime[todoId] ?? 0,
      timers: todoTimers[todoId] ?? [],
      hasActiveTimer: activeTimers.containsKey(todoId),
      activeTimerId: activeTimers[todoId],
    );
  }

  return aggregations;
}
