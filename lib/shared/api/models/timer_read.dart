// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'schedule_read.dart';
import 'tag_read.dart';
import 'todo_read.dart';
import 'visibility_level.dart';

part 'timer_read.freezed.dart';
part 'timer_read.g.dart';

/// 타이머 조회 DTO
@Freezed()
abstract class TimerRead with _$TimerRead {
  const factory TimerRead({
    required String id,
    @JsonKey(name: 'allocated_duration') required int allocatedDuration,
    @JsonKey(name: 'elapsed_time') required int elapsedTime,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'pause_history') @Default([]) List<dynamic> pauseHistory,
    @Default([]) List<TagRead> tags,
    @JsonKey(name: 'is_shared') @Default(false) bool isShared,
    @JsonKey(name: 'schedule_id') String? scheduleId,
    @JsonKey(name: 'todo_id') String? todoId,
    String? title,
    String? description,
    @JsonKey(name: 'started_at') DateTime? startedAt,
    @JsonKey(name: 'paused_at') DateTime? pausedAt,
    @JsonKey(name: 'ended_at') DateTime? endedAt,
    ScheduleRead? schedule,
    TodoRead? todo,
    @JsonKey(name: 'owner_id') String? ownerId,
    @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel,
  }) = _TimerRead;

  factory TimerRead.fromJson(Map<String, Object?> json) =>
      _$TimerReadFromJson(json);
}
