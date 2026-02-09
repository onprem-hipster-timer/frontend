// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleRead _$ScheduleReadFromJson(Map<String, dynamic> json) =>
    _ScheduleRead(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      state: ScheduleState.fromJson(json['state'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => TagRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isShared: json['is_shared'] as bool? ?? false,
      description: json['description'] as String?,
      recurrenceRule: json['recurrence_rule'] as String?,
      recurrenceEnd: json['recurrence_end'] == null
          ? null
          : DateTime.parse(json['recurrence_end'] as String),
      parentId: json['parent_id'] as String?,
      tagGroupId: json['tag_group_id'] as String?,
      sourceTodoId: json['source_todo_id'] as String?,
      ownerId: json['owner_id'] as String?,
      visibilityLevel: json['visibility_level'] == null
          ? null
          : VisibilityLevel.fromJson(json['visibility_level'] as String),
    );

Map<String, dynamic> _$ScheduleReadToJson(_ScheduleRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime.toIso8601String(),
      'state': _$ScheduleStateEnumMap[instance.state]!,
      'created_at': instance.createdAt.toIso8601String(),
      'tags': instance.tags,
      'is_shared': instance.isShared,
      'description': instance.description,
      'recurrence_rule': instance.recurrenceRule,
      'recurrence_end': instance.recurrenceEnd?.toIso8601String(),
      'parent_id': instance.parentId,
      'tag_group_id': instance.tagGroupId,
      'source_todo_id': instance.sourceTodoId,
      'owner_id': instance.ownerId,
      'visibility_level': _$VisibilityLevelEnumMap[instance.visibilityLevel],
    };

const _$ScheduleStateEnumMap = {
  ScheduleState.planned: 'PLANNED',
  ScheduleState.confirmed: 'CONFIRMED',
  ScheduleState.cancelled: 'CANCELLED',
  ScheduleState.$unknown: r'$unknown',
};

const _$VisibilityLevelEnumMap = {
  VisibilityLevel.private: 'private',
  VisibilityLevel.friends: 'friends',
  VisibilityLevel.selected: 'selected',
  VisibilityLevel.public: 'public',
  VisibilityLevel.$unknown: r'$unknown',
};
