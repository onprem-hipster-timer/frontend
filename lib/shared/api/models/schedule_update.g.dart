// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleUpdate _$ScheduleUpdateFromJson(Map<String, dynamic> json) =>
    _ScheduleUpdate(
      title: json['title'] as String?,
      description: json['description'] as String?,
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      recurrenceRule: json['recurrence_rule'] as String?,
      recurrenceEnd: json['recurrence_end'] == null
          ? null
          : DateTime.parse(json['recurrence_end'] as String),
      tagIds:
          (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
      tagGroupId: json['tag_group_id'] as String?,
      sourceTodoId: json['source_todo_id'] as String?,
      state: json['state'] == null
          ? null
          : ScheduleState.fromJson(json['state'] as String),
      visibility: json['visibility'] == null
          ? null
          : VisibilitySettings.fromJson(
              json['visibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ScheduleUpdateToJson(_ScheduleUpdate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'recurrence_rule': instance.recurrenceRule,
      'recurrence_end': instance.recurrenceEnd?.toIso8601String(),
      'tag_ids': instance.tagIds,
      'tag_group_id': instance.tagGroupId,
      'source_todo_id': instance.sourceTodoId,
      'state': _$ScheduleStateEnumMap[instance.state],
      'visibility': instance.visibility,
    };

const _$ScheduleStateEnumMap = {
  ScheduleState.planned: 'PLANNED',
  ScheduleState.confirmed: 'CONFIRMED',
  ScheduleState.cancelled: 'CANCELLED',
  ScheduleState.$unknown: r'$unknown',
};
