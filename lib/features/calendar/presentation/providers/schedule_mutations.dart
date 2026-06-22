import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';

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
    state = const AsyncValue.loading();

    try {
      final api = ref.read(schedulesApiProvider);
      final createdSchedule = await api.createScheduleV1SchedulesPost(
        body: data,
      );

      // async gap(await) 이후 provider가 dispose됐으면 ref/state를 만지지 않는다.
      // (Riverpod 3: UnmountedRefException 방지)
      if (ref.mounted) {
        ref.invalidate(currentSchedulesProvider);
        state = const AsyncValue.data(null);
      }

      debugPrint('일정이 성공적으로 생성되었습니다: ${createdSchedule.id}');
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      debugPrint('일정 생성 실패: $error');
      rethrow; // UI에서 에러 처리할 수 있도록 다시 throw
    }
  }

  /// 일정 수정
  ///
  /// [id] 수정할 일정 ID
  /// [data] 수정할 일정 정보
  Future<void> updateSchedule(
    String id,
    ScheduleUpdate data, {
    RequestOptions? options,
  }) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(schedulesApiProvider);
      final updatedSchedule = await api
          .updateScheduleV1SchedulesScheduleIdPatch(
            scheduleId: id,
            body: data,
            options: options,
          );

      // async gap(await) 이후 provider가 dispose됐으면 ref/state를 만지지 않는다.
      // (Riverpod 3: UnmountedRefException 방지)
      if (ref.mounted) {
        ref.invalidate(currentSchedulesProvider);
        state = const AsyncValue.data(null);
      }

      debugPrint('일정이 성공적으로 수정되었습니다: ${updatedSchedule.id}');
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      debugPrint('일정 수정 실패: $error');
      rethrow;
    }
  }

  /// 일정 삭제
  ///
  /// [id] 삭제할 일정 ID
  Future<void> deleteSchedule(String id) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(schedulesApiProvider);
      await api.deleteScheduleV1SchedulesScheduleIdDelete(scheduleId: id);

      // async gap(await) 이후 provider가 dispose됐으면 ref/state를 만지지 않는다.
      // (Riverpod 3: UnmountedRefException 방지)
      if (ref.mounted) {
        ref.invalidate(currentSchedulesProvider);
        state = const AsyncValue.data(null);
      }

      debugPrint('일정이 성공적으로 삭제되었습니다: $id');
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      debugPrint('일정 삭제 실패: $error');
      rethrow;
    }
  }

  /// 일정 → TODO 변환
  ///
  /// [scheduleId] 변환할 일정 ID
  /// [tagGroupId] TODO가 속할 TagGroup ID
  Future<void> convertToTodo(String scheduleId, String tagGroupId) async {
    state = const AsyncValue.loading();

    try {
      final api = ref.read(schedulesApiProvider);
      await api.createTodoFromScheduleV1SchedulesScheduleIdTodoPost(
        scheduleId: scheduleId,
        tagGroupId: tagGroupId,
      );

      // async gap(await) 이후 provider가 dispose됐으면 ref/state를 만지지 않는다.
      // (Riverpod 3: UnmountedRefException 방지)
      if (ref.mounted) {
        ref.invalidate(scheduleDetailProvider(scheduleId));
        ref.invalidate(currentSchedulesProvider);
        // 변환된 TODO가 특정 태그 그룹에 속할 수 있으므로 family 전체를 무효화한다.
        ref.invalidate(todosProvider);
        state = const AsyncValue.data(null);
      }

      debugPrint('일정이 TODO로 변환되었습니다: $scheduleId');
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      debugPrint('TODO 변환 실패: $error');
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
