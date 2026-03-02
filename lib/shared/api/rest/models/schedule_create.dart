// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'create_todo_options.dart';
import 'schedule_state.dart';
import 'visibility_settings.dart';

part 'schedule_create.freezed.dart';
part 'schedule_create.g.dart';

/// 일정 생성 DTO
@Freezed()
abstract class ScheduleCreate with _$ScheduleCreate {
  const factory ScheduleCreate({
    required String title,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    @Default(ScheduleState.planned) ScheduleState? state,
    String? description,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'recurrence_end') DateTime? recurrenceEnd,
    @JsonKey(name: 'tag_ids') List<String>? tagIds,
    @JsonKey(name: 'tag_group_id') String? tagGroupId,
    @JsonKey(name: 'source_todo_id') String? sourceTodoId,
    @JsonKey(name: 'create_todo_options') CreateTodoOptions? createTodoOptions,
    VisibilitySettings? visibility,
  }) = _ScheduleCreate;

  factory ScheduleCreate.fromJson(Map<String, Object?> json) =>
      _$ScheduleCreateFromJson(json);
}
