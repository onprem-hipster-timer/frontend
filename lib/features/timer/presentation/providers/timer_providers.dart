import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/utils/timezone_utils.dart';
import 'package:momeet/features/timer/data/timer_repository_impl.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/providers/api_providers.dart';

part 'timer_providers.g.dart';

// ============================================================
// Timer WebSocket Client
// ============================================================

/// 타이머 WebSocket 클라이언트
///
/// 로그인된 경우에만 non-null. 토큰이 없거나 비어 있으면 null.
/// 기기 타임존을 쿼리로 전달해 서버 응답 타임스탬프를 해당 타임존으로 받습니다.
final timerWsClientProvider = Provider<TimerWsClient?>((ref) {
  final token = ref.watch(accessTokenProvider);
  if (token == null || token.isEmpty) return null;

  final timezone = deviceTimezoneOffsetString();
  final client = TimerWsClient(accessToken: token, timezone: timezone);
  ref.onDispose(() => client.dispose());

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
  return TimerRepositoryImpl(client);
});

// ============================================================
// Timer Data Providers
// ============================================================

/// 마지막 WebSocket 에러 (서버 error 메시지 수신 시 설정, UI에서 에러 배너로 표시·닫기 시 초기화)
class TimerWsLastErrorNotifier extends Notifier<TimerWsError?> {
  @override
  TimerWsError? build() => null;

  void setError(TimerWsError? error) => state = error;
}

final timerWsLastErrorProvider =
    NotifierProvider<TimerWsLastErrorNotifier, TimerWsError?>(
      TimerWsLastErrorNotifier.new,
    );

/// 활성 타이머 조회 (실시간)
///
/// 초기 1회 REST 조회 후, WebSocket 이벤트(timer.created / updated / completed / sync_result) payload로만 갱신합니다.
@riverpod
Stream<TimerRead?> activeTimer(Ref ref) async* {
  final repository = ref.watch(timerRepositoryProvider);

  TimerRead? initial;
  try {
    initial = await repository.getActiveTimer();
  } catch (error) {
    debugPrint('활성 타이머 조회 실패: $error');
    initial = null;
  }
  yield initial;

  final client = ref.watch(timerWsClientProvider);
  if (client == null) return;

  await for (final event in client.messageStream) {
    switch (event) {
      case TimerWsConnected():
        client.resetReconnectAttempts();
      case TimerWsTimerCreated(timer: final timer):
      case TimerWsTimerUpdated(timer: final timer):
        ref.invalidate(timerHistoryProvider);
        yield timer;
      case TimerWsTimerCompleted():
        ref.invalidate(timerHistoryProvider);
        yield null;
      case TimerWsSyncResult():
        ref.invalidate(timerHistoryProvider);
        if (event.timers.isEmpty) {
          yield null;
        } else {
          final sorted = List<TimerRead>.from(event.timers)
            ..sort((a, b) {
              final aStart = a.startedAt ?? a.createdAt;
              final bStart = b.startedAt ?? b.createdAt;
              return bStart.compareTo(aStart);
            });
          yield sorted.first;
        }
      case TimerWsError():
        ref.read(timerWsLastErrorProvider.notifier).setError(event);
      default:
        break;
    }
  }
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

// ============================================================
// Timer Ticker Provider (Local UI Ticker)
// ============================================================

/// 실시간 타이머 틱 제공
///
/// - RUNNING: 서버 `elapsed_time` + (now - paused_at이 없으면 now - started_at 보정분)을 1초마다 갱신
/// - PAUSED: 서버 `elapsed_time`을 그대로 유지 (0으로 리셋하지 않음)
/// - null/기타: Duration.zero
@riverpod
Stream<Duration> timerTicker(Ref ref) async* {
  final activeTimerAsync = ref.watch(activeTimerProvider);

  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    final activeTimer = activeTimerAsync.when(
      data: (timer) => timer,
      loading: () => null,
      error: (error, stack) => null,
    );

    yield calculateElapsed(
      status: activeTimer?.status,
      elapsedTime: activeTimer?.elapsedTime ?? 0,
      startedAt: activeTimer?.startedAt,
      pausedAt: activeTimer?.pausedAt,
    );
  }
}

// ============================================================
// Timer Controller (Mutation)
// ============================================================

/// 타이머 제어 로직
///
/// 타이머 시작/정지 등의 CUD 작업을 담당합니다.
@riverpod
class TimerController extends _$TimerController {
  @override
  FutureOr<void> build() {}

  /// 타이머 시작
  ///
  /// WebSocket으로 timer.create 전송. 서버가 timer.created를 보내면
  /// activeTimer 스트림이 payload로 즉시 갱신됩니다.
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    state = const AsyncValue.loading();

    try {
      final ws = ref.read(timerWsClientProvider);
      if (ws != null && ws.isConnected) {
        ws.createTimer(
          todoId: relatedTodoId,
          scheduleId: scheduleId,
          title: title ?? '새 작업',
          allocatedDuration: allocatedDurationSeconds ?? 3600,
        );
        state = const AsyncValue.data(null);
        return;
      }
      throw Exception('WebSocket에 연결되어 있지 않습니다. 로그인 후 다시 시도하세요.');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 타이머 정지
  ///
  /// [timerId]를 주면 해당 타이머를 정지하고, 생략 시 활성 타이머를 정지합니다.
  Future<void> stopTimer({String? timerId}) async {
    state = const AsyncValue.loading();

    try {
      final id =
          timerId ??
          ref
              .read(activeTimerProvider)
              .when(
                data: (timer) => timer?.id,
                loading: () => null,
                error: (_, __) => null,
              );
      if (id == null) {
        throw Exception('정지할 활성 타이머가 없습니다');
      }

      final ws = ref.read(timerWsClientProvider);
      if (ws != null && ws.isConnected) {
        ws.stopTimer(id);
        ref.invalidate(timerHistoryProvider);
        state = const AsyncValue.data(null);
        return;
      }

      final repository = ref.read(timerRepositoryProvider);
      await repository.updateTimer(id, const TimerUpdate());
      state = const AsyncValue.data(null);
      ref.invalidate(timerHistoryProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 타이머 일시정지
  ///
  /// [timerId]를 주면 해당 타이머를 일시정지하고, 생략 시 활성 타이머를 일시정지합니다.
  Future<void> pauseTimer({String? timerId}) async {
    state = const AsyncValue.loading();

    try {
      final activeTimer = ref
          .read(activeTimerProvider)
          .when(
            data: (timer) => timer,
            loading: () => null,
            error: (error, stack) => null,
          );
      final id = timerId ?? activeTimer?.id;
      if (id == null) {
        throw Exception('일시정지할 실행 중인 타이머가 없습니다');
      }
      if (timerId == null &&
          (activeTimer == null || activeTimer.status != TimerStatus.running)) {
        throw Exception('일시정지할 실행 중인 타이머가 없습니다');
      }

      final ws = ref.read(timerWsClientProvider);
      if (ws != null && ws.isConnected) {
        ws.pauseTimer(id);
        state = const AsyncValue.data(null);
        return;
      }

      final repository = ref.read(timerRepositoryProvider);
      await repository.updateTimer(id, const TimerUpdate());
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 타이머 재개
  ///
  /// [timerId]를 주면 해당 타이머를 재개하고, 생략 시 활성 타이머를 재개합니다.
  Future<void> resumeTimer({String? timerId}) async {
    state = const AsyncValue.loading();

    try {
      final activeTimer = ref
          .read(activeTimerProvider)
          .when(
            data: (timer) => timer,
            loading: () => null,
            error: (error, stack) => null,
          );
      final id = timerId ?? activeTimer?.id;
      if (id == null) {
        throw Exception('재개할 일시정지된 타이머가 없습니다');
      }
      if (timerId == null &&
          (activeTimer == null || activeTimer.status != TimerStatus.paused)) {
        throw Exception('재개할 일시정지된 타이머가 없습니다');
      }

      final ws = ref.read(timerWsClientProvider);
      if (ws != null && ws.isConnected) {
        ws.resumeTimer(id);
        state = const AsyncValue.data(null);
        return;
      }

      final repository = ref.read(timerRepositoryProvider);
      await repository.updateTimer(id, const TimerUpdate());
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
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
// Timer Elapsed Calculation (순수 함수 — 테스트 용이)
// ============================================================

/// 타이머의 현재 경과 시간을 계산합니다.
///
/// - [status]가 null이면 Duration.zero
/// - PAUSED / COMPLETED 등 비실행 상태: [elapsedTime] 그대로
/// - RUNNING: [elapsedTime] + (now - [resumedAt]) 보정
Duration calculateElapsed({
  required TimerStatus? status,
  required int elapsedTime,
  DateTime? startedAt,
  DateTime? pausedAt,
  DateTime? now,
}) {
  if (status == null) return Duration.zero;

  if (status != TimerStatus.running) {
    return Duration(seconds: elapsedTime);
  }

  final currentTime = now ?? DateTime.now().toUtc();
  final resumedAt = pausedAt ?? startedAt;
  if (resumedAt == null) {
    return Duration(seconds: elapsedTime);
  }

  final currentSegment = currentTime.difference(resumedAt).inSeconds;
  final totalSeconds = elapsedTime + currentSegment;
  return Duration(seconds: totalSeconds.clamp(0, double.infinity).toInt());
}

// ============================================================
// Utility Functions
// ============================================================

/// Duration을 HH:MM:SS 형식의 문자열로 변환
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// DateTime을 HH:MM 형식으로 변환 (시간 표시용)
String formatTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

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
