import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/utils/timezone_utils.dart';
import 'package:momeet/features/timer/data/timer_repository_impl.dart';
import 'package:momeet/features/timer/domain/timer_repository.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/providers/api_providers.dart';

part 'timer_providers.g.dart';

// ============================================================
// Timer WebSocket Client
// ============================================================

/// 타이머 WebSocket 클라이언트
///
/// 로그인된 경우에만 non-null. JWT가 아니라 사용자 ID를 지켜보므로, JWT가 갱신될 때마다
/// 소켓을 다시 열지 않는다. 클라이언트가 (재)연결할 때마다 최신 JWT를 받아 쓴다.
/// 기기 타임존을 쿼리로 전달해 서버 응답 타임스탬프를 해당 타임존으로 받습니다.
final timerWsClientProvider = Provider<TimerWsClient?>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.id));
  if (userId == null) return null;

  final auth = ref.read(authProvider.notifier);
  final timezone = deviceTimezoneOffsetString();
  final client = TimerWsClient(
    accessToken: auth.freshAccessToken,
    timezone: timezone,
  );
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

/// 친구 타이머 활동 알림 스트림
///
/// 타이머 화면에서 SnackBar를 띄우기 위한 UI-scoped 스트림.
/// 화면을 벗어나 listener가 모두 사라지면 WS 구독을 정리하도록 autoDispose.
final timerFriendActivityProvider =
    StreamProvider.autoDispose<TimerWsFriendActivity>((ref) async* {
      final client = ref.watch(timerWsClientProvider);
      if (client == null) return;

      await for (final event in client.messageStream) {
        if (event case TimerWsFriendActivity()) {
          yield event;
        }
      }
    });

/// 활성 타이머 조회 (실시간)
///
/// 초기 1회 REST 조회 후, WebSocket 이벤트(timer.created / updated) payload로만 갱신합니다.
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
        ref.invalidate(timerHistoryProvider);
        yield timer;
      case TimerWsTimerUpdated(timer: final timer):
        // 완료/취소 상태가 오면 활성 타이머 없음으로 간주해 null을 흘려보낸다.
        ref.invalidate(timerHistoryProvider);
        if (timer == null ||
            timer.status == TimerStatus.completed ||
            timer.status == TimerStatus.cancelled) {
          yield null;
        } else {
          yield timer;
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

/// 활성 타이머의 표시 경과 시간 ([displayElapsed], 서버 시각 기준)을 1초마다 갱신. 활성 타이머가 없으면 Duration.zero
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
        : displayElapsed(activeTimer, clock.now());
  }
}

// ============================================================
// Timer Controller (Mutation)
// ============================================================

/// 타이머 제어 로직
///
/// 타이머 시작/정지 등의 명령을 REST로 보낸다. 바뀐 상태는 실시간 이벤트로도 들어온다.
@riverpod
class TimerController extends _$TimerController {
  @override
  FutureOr<void> build() {}

  /// 타이머 시작
  Future<void> startTimer({
    String? relatedTodoId,
    String? title,
    String? scheduleId,
    int? allocatedDurationSeconds,
  }) async {
    state = const AsyncValue.loading();

    try {
      await ref
          .read(timerRepositoryProvider)
          .createTimer(
            TimerCreate(
              todoId: relatedTodoId,
              scheduleId: scheduleId,
              title: title ?? '새 작업',
              allocatedDuration: allocatedDurationSeconds ?? 3600,
            ),
          );
      ref.invalidate(timerHistoryProvider);
      state = const AsyncValue.data(null);
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
                error: (_, _) => null,
              );
      if (id == null) {
        throw Exception('정지할 활성 타이머가 없습니다');
      }

      await ref.read(timerRepositoryProvider).stopTimer(id);
      ref.invalidate(timerHistoryProvider);
      state = const AsyncValue.data(null);
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

      await ref.read(timerRepositoryProvider).pauseTimer(id);
      ref.invalidate(timerHistoryProvider);
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

      await ref.read(timerRepositoryProvider).resumeTimer(id);
      ref.invalidate(timerHistoryProvider);
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
