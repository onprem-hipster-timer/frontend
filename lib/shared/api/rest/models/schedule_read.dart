// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'schedule_state.dart';
import 'tag_read.dart';
import 'visibility_level.dart';

part 'schedule_read.freezed.dart';
part 'schedule_read.g.dart';

/// 일정 조회 DTO
@Freezed()
abstract class ScheduleRead with _$ScheduleRead {
  const factory ScheduleRead({
    required String id,
    required String title,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    required ScheduleState state,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default([]) List<TagRead> tags,
    @JsonKey(name: 'is_shared') @Default(false) bool isShared,
    String? description,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'tag_group_id') String? tagGroupId,
    @JsonKey(name: 'source_todo_id') String? sourceTodoId,
    @JsonKey(name: 'owner_id') String? ownerId,
    @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel,
  }) = _ScheduleRead;

  factory ScheduleRead.fromJson(Map<String, Object?> json) =>
      _$ScheduleReadFromJson(json);
}
