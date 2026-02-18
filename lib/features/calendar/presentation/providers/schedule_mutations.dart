import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';

part 'schedule_mutations.g.dart';

// ============================================================
// 일정 Mutation Provider (생성/수정/삭제)
// ============================================================

/// 일정 Mutation 상태 관리
///
/// 일정 생성, 수정, 삭제 등의 상태 변경 작업을 관리합니다.
/// AsyncValue를 사용하여 로딩/성공/에러 상태를 추적합니다.
@riverpod
class ScheduleMutations extends _$ScheduleMutations {
  @override
  FutureOr<void> build() {}

  /// 새로운 일정 생성
  ///
  /// [data] 생성할 일정 정보
  /// 성공 시 일정 목록을 새로고침하고, UI 로딩 상태를 관리합니다.
  Future<void> createSchedule(ScheduleCreate data) async {
    // 이미 dispose된 상태인지 확인
    if (!ref.mounted) return;

    // 로딩 상태로 설정
    state = const AsyncValue.loading();

    try {
      final api = ref.read(schedulesApiProvider);

      // API 호출하여 일정 생성
      final createdSchedule =
          await api.createScheduleV1SchedulesPost(body: data);

      // provider가 dispose되지 않았는지 확인
      if (!ref.mounted) return;

      // 성공 상태로 설정
      state = const AsyncValue.data(null);

      // 캘린더 목록 새로고침 (현재 화면에 새 일정이 바로 표시되도록)
      ref.invalidate(currentSchedulesProvider);

      debugPrint('일정이 성공적으로 생성되었습니다: ${createdSchedule.id}');
    } catch (error, stackTrace) {
      // provider가 dispose되지 않았는지 확인
      if (!ref.mounted) return;

      // 에러 상태로 설정
      state = AsyncValue.error(error, stackTrace);

      // 에러 로깅
      debugPrint('일정 생성 실패: $error');
      rethrow; // UI에서 에러 처리할 수 있도록 다시 throw
    }
  }

  /// 일정 수정
  ///
  /// [id] 수정할 일정 ID
  /// [data] 수정할 일정 정보
  Future<void> updateSchedule(String id, ScheduleUpdate data) async {
    // 이미 dispose된 상태인지 확인
    if (!ref.mounted) return;

    state = const AsyncValue.loading();

    try {
      final api = ref.read(schedulesApiProvider);

      final updatedSchedule =
          await api.updateScheduleV1SchedulesScheduleIdPatch(
        scheduleId: id,
        body: data,
      );

      // provider가 dispose되지 않았는지 확인
      if (!ref.mounted) return;

      state = const AsyncValue.data(null);
      ref.invalidate(currentSchedulesProvider);

      debugPrint('일정이 성공적으로 수정되었습니다: ${updatedSchedule.id}');
    } catch (error, stackTrace) {
      // provider가 dispose되지 않았는지 확인
      if (!ref.mounted) return;

      state = AsyncValue.error(error, stackTrace);
      debugPrint('일정 수정 실패: $error');
      rethrow;
    }
  }

  /// 일정 삭제
  ///
  /// [id] 삭제할 일정 ID
  Future<void> deleteSchedule(String id) async {
    // 이미 dispose된 상태인지 확인
    if (!ref.mounted) return;

    state = const AsyncValue.loading();

    try {
      final api = ref.read(schedulesApiProvider);

      await api.deleteScheduleV1SchedulesScheduleIdDelete(scheduleId: id);

      // provider가 dispose되지 않았는지 확인
      if (!ref.mounted) return;

      state = const AsyncValue.data(null);
      ref.invalidate(currentSchedulesProvider);

      debugPrint('일정이 성공적으로 삭제되었습니다: $id');
    } catch (error, stackTrace) {
      // provider가 dispose되지 않았는지 확인
      if (!ref.mounted) return;

      state = AsyncValue.error(error, stackTrace);
      debugPrint('일정 삭제 실패: $error');
      rethrow;
    }
  }

  /// 일정 이동 (드래그 앤 드롭용)
  ///
  /// [id] 이동할 일정 ID
  /// [newStartTime] 새로운 시작 시간
  /// [newEndTime] 새로운 종료 시간
  Future<void> moveSchedule(
    String id, {
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    final scheduleUpdate = ScheduleUpdate(
      startTime: newStartTime.toUtc(),
      endTime: newEndTime.toUtc(),
    );

    await updateSchedule(id, scheduleUpdate);
  }

  /// 일정 리사이즈 (시간 조절용)
  ///
  /// [id] 리사이즈할 일정 ID
  /// [newStartTime] 새로운 시작 시간 (null이면 기존 유지)
  /// [newEndTime] 새로운 종료 시간
  Future<void> resizeSchedule(
    String id, {
    DateTime? newStartTime,
    required DateTime newEndTime,
  }) async {
    final scheduleUpdate = ScheduleUpdate(
      startTime: newStartTime?.toUtc(),
      endTime: newEndTime.toUtc(),
    );

    await updateSchedule(id, scheduleUpdate);
  }
}
