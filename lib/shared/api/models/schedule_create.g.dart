// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleCreate _$ScheduleCreateFromJson(Map<String, dynamic> json) =>
    _ScheduleCreate(
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      state: json['state'] == null
          ? ScheduleState.planned
          : ScheduleState.fromJson(json['state'] as String),
      description: json['description'] as String?,
      recurrenceRule: json['recurrence_rule'] as String?,
      recurrenceEnd: json['recurrence_end'] == null
          ? null
          : DateTime.parse(json['recurrence_end'] as String),
      tagIds:
          (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
      tagGroupId: json['tag_group_id'] as String?,
      sourceTodoId: json['source_todo_id'] as String?,
      createTodoOptions: json['create_todo_options'] == null
          ? null
          : CreateTodoOptions.fromJson(
              json['create_todo_options'] as Map<String, dynamic>),
      visibility: json['visibility'] == null
          ? null
          : VisibilitySettings.fromJson(
              json['visibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ScheduleCreateToJson(_ScheduleCreate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'state': _$ScheduleStateEnumMap[instance.state],
      'description': instance.description,
      'recurrence_rule': instance.recurrenceRule,
      'recurrence_end': instance.recurrenceEnd?.toIso8601String(),
      'tag_ids': instance.tagIds,
      'tag_group_id': instance.tagGroupId,
      'source_todo_id': instance.sourceTodoId,
      'create_todo_options': instance.createTodoOptions,
      'visibility': instance.visibility,
    };

const _$ScheduleStateEnumMap = {
  ScheduleState.planned: 'PLANNED',
  ScheduleState.confirmed: 'CONFIRMED',
  ScheduleState.cancelled: 'CANCELLED',
  ScheduleState.$unknown: r'$unknown',
};
