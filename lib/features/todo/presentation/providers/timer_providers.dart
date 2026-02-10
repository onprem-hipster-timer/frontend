import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/export.dart';
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
    );

    return response;
  } catch (error) {
    throw Exception('타이머 조회 실패: $error');
  }
}

/// 활성 타이머만 조회 (RUNNING, PAUSED 상태)
@riverpod
Future<List<TimerRead>> activeTimers(Ref ref) async {
  return ref.watch(timersProvider(status: ['RUNNING', 'PAUSED']).future);
}

/// Todo별 타이머 집계 데이터
@riverpod
Future<Map<String, TodoTimerAggregation>> todoTimerAggregations(Ref ref) async {
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
@riverpod
Stream<Map<String, ActiveTimerState>> activeTimerStream(Ref ref) async* {
  // 처음에는 현재 활성 타이머 조회
  final activeTimers = await ref.watch(activeTimersProvider.future);

  yield* Stream.periodic(const Duration(seconds: 1), (count) {
    final now = DateTime.now();
    final activeStates = <String, ActiveTimerState>{};

    for (final timer in activeTimers) {
      if (timer.status == 'RUNNING' && timer.startedAt != null) {
        final elapsedSinceStart = now.difference(timer.startedAt!).inSeconds;
        final totalElapsed = timer.elapsedTime + elapsedSinceStart;

        activeStates[timer.todoId ?? timer.scheduleId ?? timer.id] = ActiveTimerState(
          timerId: timer.id,
          elapsedSeconds: totalElapsed,
          status: timer.status,
          startedAt: timer.startedAt,
          pausedAt: timer.pausedAt,
        );
      } else if (timer.status == 'PAUSED') {
        activeStates[timer.todoId ?? timer.scheduleId ?? timer.id] = ActiveTimerState(
          timerId: timer.id,
          elapsedSeconds: timer.elapsedTime,
          status: timer.status,
          startedAt: timer.startedAt,
          pausedAt: timer.pausedAt,
        );
      }
    }

    return MapEntry(count, activeStates);
  }).asyncMap((entry) async {
    final count = entry.key;
    final states = entry.value;

    // 상태가 변경되면 활성 타이머 다시 조회 (10초마다)
    if (count % 10 == 0) {
      try {
        final _ = await ref.refresh(activeTimersProvider.future);
      } catch (error) {
        debugPrint('활성 타이머 재조회 실패: $error');
      }
    }
    return states;
  });
}

// ============================================================
// Timer Mutation Provider
// ============================================================

/// 타이머 관련 CUD 작업
@riverpod
class TimerMutations extends _$TimerMutations {
  @override
  FutureOr<void> build() {}

  /// 타이머 업데이트 (현재 사용 가능한 유일한 메서드)
  Future<TimerRead> updateTimer(String timerId, TimerUpdate data) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(timersApiProvider);
      final result = await api.updateTimerV1TimersTimerIdPatch(
        timerId: timerId,
        body: data,
      );

      state = const AsyncValue.data(null);

      // 관련 데이터 새로고침
      ref.invalidate(timersProvider());
      ref.invalidate(activeTimersProvider);
      ref.invalidate(todoTimerAggregationsProvider);

      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 타이머 삭제
  Future<void> deleteTimer(String timerId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(timersApiProvider);
      await api.deleteTimerV1TimersTimerIdDelete(timerId: timerId);

      state = const AsyncValue.data(null);

      // 관련 데이터 새로고침
      ref.invalidate(timersProvider());
      ref.invalidate(activeTimersProvider);
      ref.invalidate(todoTimerAggregationsProvider);

    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

// ============================================================
// Helper Classes & Functions
// ============================================================

/// Todo별 타이머 집계 데이터
class TodoTimerAggregation {
  final String todoId;
  final int totalElapsedSeconds; // 본인 + 하위 Todo의 총 시간
  final int ownElapsedSeconds;   // 본인만의 시간
  final List<TimerRead> timers;  // 연결된 타이머들
  final bool hasActiveTimer;     // 활성 타이머 여부
  final String? activeTimerId;   // 활성 타이머 ID

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
  final String status;
  final DateTime? startedAt;
  final DateTime? pausedAt;

  const ActiveTimerState({
    required this.timerId,
    required this.elapsedSeconds,
    required this.status,
    this.startedAt,
    this.pausedAt,
  });

  bool get isRunning => status == 'RUNNING';
  bool get isPaused => status == 'PAUSED';

  /// 경과 시간을 HH:MM:SS 형태로 포맷
  String get formattedTime => TodoTimerAggregation._formatDuration(elapsedSeconds);
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
      todoOwnTime[timer.todoId!] = (todoOwnTime[timer.todoId!] ?? 0) + timer.elapsedTime;

      if (timer.status == 'RUNNING' || timer.status == 'PAUSED') {
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
