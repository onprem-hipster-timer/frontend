import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/export.dart';

part 'timer_providers.g.dart';

// ============================================================
// Timer Data Providers
// ============================================================

/// 활성 타이머 조회 (Backend Sync)
///
/// API를 호출하여 현재 서버에서 실행 중인 타이머가 있는지 확인합니다.
/// 실행 중인 타이머가 없으면 null을 반환합니다.
@riverpod
Future<TimerRead?> activeTimer(Ref ref) async {
  final api = ref.watch(timersApiProvider);

  try {
    final timer = await api.getUserActiveTimerV1TimersActiveGet(
      includeTodo: true,
      includeSchedule: true,
    );
    return timer;
  } catch (error) {
    // 404는 활성 타이머가 없다는 의미이므로 null 반환
    if (error.toString().contains('404')) {
      return null;
    }
    debugPrint('활성 타이머 조회 실패: $error');
    return null;
  }
}

/// 타이머 히스토리 조회
///
/// 과거 완료된 타이머 기록을 조회합니다.
@riverpod
Future<List<TimerRead>> timerHistory(Ref ref) async {
  final api = ref.watch(timersApiProvider);

  try {
    final timers = await api.listTimersV1TimersGet(
      status: ['COMPLETED'],
      includeTodo: true,
      includeSchedule: true,
    );

    // 시작 시간 기준으로 최신순 정렬
    final sortedTimers = List<TimerRead>.from(timers);
    sortedTimers.sort((a, b) {
      final aStarted = a.startedAt ?? a.createdAt;
      final bStarted = b.startedAt ?? b.createdAt;
      return bStarted.compareTo(aStarted);
    });

    return sortedTimers;
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
/// 활성 타이머가 있다면 1초마다 현재 경과 시간을 계산해서 Duration으로 방출합니다.
/// 활성 타이머가 없다면 Duration.zero를 방출합니다.
@riverpod
Stream<Duration> timerTicker(Ref ref) async* {
  // 활성 타이머 상태를 구독
  final activeTimerAsync = ref.watch(activeTimerProvider);

  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    final activeTimer = activeTimerAsync.when(
      data: (timer) => timer,
      loading: () => null,
      error: (error, stack) => null,
    );

    if (activeTimer == null ||
        activeTimer.status != 'RUNNING' ||
        activeTimer.startedAt == null) {
      yield Duration.zero;
      continue;
    }

    // 현재 시간과 시작 시간의 차이 계산
    final now = DateTime.now().toUtc();
    final startedAt = activeTimer.startedAt!;
    final baseDuration = now.difference(startedAt);

    // 기존 경과 시간(일시정지 시간 포함) 추가
    final totalSeconds = baseDuration.inSeconds + activeTimer.elapsedTime;

    yield Duration(seconds: totalSeconds.clamp(0, double.infinity).toInt());
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
  /// 현재는 타이머 생성 API가 없으므로 placeholder 구현입니다.
  /// 실제로는 TimerCreate 데이터로 POST 요청을 보내야 합니다.
  Future<TimerRead> startTimer({String? relatedTodoId, String? title}) async {
    state = const AsyncValue.loading();

    try {
      // TODO: 실제 타이머 생성 API 구현 필요
      // final api = ref.read(timersApiProvider);
      // final newTimer = await api.createTimerV1TimersPost(
      //   body: TimerCreate(
      //     todoId: relatedTodoId,
      //     title: title ?? '새 작업',
      //     allocatedDuration: null,
      //   ),
      // );

      // 임시로 mock 데이터 반환
      throw UnimplementedError('타이머 생성 API가 아직 구현되지 않았습니다');

      // state = const AsyncValue.data(null);
      //
      // // 활성 타이머와 히스토리 새로고침
      // ref.invalidate(activeTimerProvider);
      // ref.invalidate(timerHistoryProvider);
      //
      // return newTimer;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 타이머 정지
  ///
  /// 현재 활성 타이머를 종료합니다.
  Future<void> stopTimer() async {
    state = const AsyncValue.loading();

    try {
      final activeTimer = ref.read(activeTimerProvider).when(
            data: (timer) => timer,
            loading: () => null,
            error: (error, stack) => null,
          );
      if (activeTimer == null) {
        throw Exception('정지할 활성 타이머가 없습니다');
      }

      final api = ref.read(timersApiProvider);

      // 타이머 종료 시간 설정
      await api.updateTimerV1TimersTimerIdPatch(
        timerId: activeTimer.id,
        body: TimerUpdate(
            // endedAt을 설정하려고 하지만 TimerUpdate에 해당 필드가 없을 수 있음
            // 실제 API 스펙에 맞게 조정 필요
            ),
      );

      state = const AsyncValue.data(null);

      // 관련 Provider들 새로고침
      ref.invalidate(activeTimerProvider);
      ref.invalidate(timerHistoryProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 타이머 일시정지
  ///
  /// 현재 활성 타이머를 일시정지합니다.
  Future<void> pauseTimer() async {
    state = const AsyncValue.loading();

    try {
      final activeTimer = ref.read(activeTimerProvider).when(
            data: (timer) => timer,
            loading: () => null,
            error: (error, stack) => null,
          );
      if (activeTimer == null || activeTimer.status != 'RUNNING') {
        throw Exception('일시정지할 실행 중인 타이머가 없습니다');
      }

      final api = ref.read(timersApiProvider);

      // 일시정지 처리 (실제 API 스펙에 맞게 구현 필요)
      await api.updateTimerV1TimersTimerIdPatch(
        timerId: activeTimer.id,
        body: const TimerUpdate(),
      );

      state = const AsyncValue.data(null);

      // 활성 타이머 새로고침
      ref.invalidate(activeTimerProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// 타이머 재개
  ///
  /// 일시정지된 타이머를 재개합니다.
  Future<void> resumeTimer() async {
    state = const AsyncValue.loading();

    try {
      final activeTimer = ref.read(activeTimerProvider).when(
            data: (timer) => timer,
            loading: () => null,
            error: (error, stack) => null,
          );
      if (activeTimer == null || activeTimer.status != 'PAUSED') {
        throw Exception('재개할 일시정지된 타이머가 없습니다');
      }

      final api = ref.read(timersApiProvider);

      // 재개 처리 (실제 API 스펙에 맞게 구현 필요)
      await api.updateTimerV1TimersTimerIdPatch(
        timerId: activeTimer.id,
        body: const TimerUpdate(),
      );

      state = const AsyncValue.data(null);

      // 활성 타이머 새로고침
      ref.invalidate(activeTimerProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
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
