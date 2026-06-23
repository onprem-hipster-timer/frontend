import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/experimental/mutation.dart';
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

/// 일정 CUD side-effect + 관련 provider invalidation을 담당하는 command Notifier.
///
/// UI 작업 상태(pending/error/success)는 아래의 [Mutation]들이 담당한다(#66 전역 반영).
/// 항상 `mutation.run(ref, (tsx) => tsx.get(scheduleMutationsProvider.notifier)
/// .xxx())` 형태로 호출되며, tsx.get이 run 동안 이 notifier를 alive로 유지하므로
/// 호출 화면이 먼저 dispose돼도 invalidate가 정상 실행된다(ref.mounted 가드 불필요).
@riverpod
class ScheduleMutations extends _$ScheduleMutations {
  @override
  void build() {}

  /// 새로운 일정 생성
  ///
  /// [data] 생성할 일정 정보
  /// 성공 시 일정 목록을 새로고침하고, UI 로딩 상태를 관리합니다.
  Future<void> createSchedule(ScheduleCreate data) async {
    try {
      final api = ref.read(schedulesApiProvider);
      final createdSchedule = await api.createScheduleV1SchedulesPost(
        body: data,
      );
      ref.invalidate(currentSchedulesProvider);
      debugPrint('일정이 성공적으로 생성되었습니다: ${createdSchedule.id}');
    } catch (error) {
      debugPrint('일정 생성 실패: $error');
      rethrow;
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
    try {
      final api = ref.read(schedulesApiProvider);
      final updatedSchedule = await api
          .updateScheduleV1SchedulesScheduleIdPatch(
            scheduleId: id,
            body: data,
            options: options,
          );
      ref.invalidate(currentSchedulesProvider);
      debugPrint('일정이 성공적으로 수정되었습니다: ${updatedSchedule.id}');
    } catch (error) {
      debugPrint('일정 수정 실패: $error');
      rethrow;
    }
  }

  /// 일정 삭제
  ///
  /// [id] 삭제할 일정 ID
  Future<void> deleteSchedule(String id) async {
    try {
      final api = ref.read(schedulesApiProvider);
      await api.deleteScheduleV1SchedulesScheduleIdDelete(scheduleId: id);
      ref.invalidate(currentSchedulesProvider);
      debugPrint('일정이 성공적으로 삭제되었습니다: $id');
    } catch (error) {
      debugPrint('일정 삭제 실패: $error');
      rethrow;
    }
  }

  /// 일정 → TODO 변환
  ///
  /// [scheduleId] 변환할 일정 ID
  /// [tagGroupId] TODO가 속할 TagGroup ID
  Future<void> convertToTodo(String scheduleId, String tagGroupId) async {
    try {
      final api = ref.read(schedulesApiProvider);
      await api.createTodoFromScheduleV1SchedulesScheduleIdTodoPost(
        scheduleId: scheduleId,
        tagGroupId: tagGroupId,
      );
      ref.invalidate(scheduleDetailProvider(scheduleId));
      ref.invalidate(currentSchedulesProvider);
      // 변환된 TODO가 특정 태그 그룹에 속할 수 있으므로 family 전체를 무효화한다.
      ref.invalidate(todosProvider);
      debugPrint('일정이 TODO로 변환되었습니다: $scheduleId');
    } catch (error) {
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

// ============================================================
// Mutations (UI operation state)
// ============================================================

/// 일정 CUD의 UI 작업 상태(pending/error/success)를 담는 Mutation들.
///
/// 사용 예: `await deleteScheduleMutation.run(ref, (tsx) =>
/// tsx.get(scheduleMutationsProvider.notifier).deleteSchedule(id));`
final createScheduleMutation = Mutation<void>(label: 'createSchedule');
final updateScheduleMutation = Mutation<void>(label: 'updateSchedule');
final deleteScheduleMutation = Mutation<void>(label: 'deleteSchedule');
final convertToTodoMutation = Mutation<void>(label: 'convertScheduleToTodo');
