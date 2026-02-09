// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'schedule_state.dart';
import 'visibility_settings.dart';

part 'schedule_update.freezed.dart';
part 'schedule_update.g.dart';

/// 일정 업데이트 DTO
@Freezed()
abstract class ScheduleUpdate with _$ScheduleUpdate {
  const factory ScheduleUpdate({
    String? title,
    String? description,
    @JsonKey(name: 'start_time')
    DateTime? startTime,
    @JsonKey(name: 'end_time')
    DateTime? endTime,
    @JsonKey(name: 'recurrence_rule')
    String? recurrenceRule,
    @JsonKey(name: 'recurrence_end')
    DateTime? recurrenceEnd,
    @JsonKey(name: 'tag_ids')
    List<String>? tagIds,
    @JsonKey(name: 'tag_group_id')
    String? tagGroupId,
    @JsonKey(name: 'source_todo_id')
    String? sourceTodoId,
    ScheduleState? state,
    VisibilitySettings? visibility,
  }) = _ScheduleUpdate;
  
  factory ScheduleUpdate.fromJson(Map<String, Object?> json) => _$ScheduleUpdateFromJson(json);
}
