// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TodoUpdate _$TodoUpdateFromJson(Map<String, dynamic> json) => _TodoUpdate(
      title: json['title'] as String?,
      description: json['description'] as String?,
      tagGroupId: json['tag_group_id'] as String?,
      tagIds:
          (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      parentId: json['parent_id'] as String?,
      status: json['status'] == null
          ? null
          : TodoStatus.fromJson(json['status'] as String),
      visibility: json['visibility'] == null
          ? null
          : VisibilitySettings.fromJson(
              json['visibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TodoUpdateToJson(_TodoUpdate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'tag_group_id': instance.tagGroupId,
      'tag_ids': instance.tagIds,
      'deadline': instance.deadline?.toIso8601String(),
      'parent_id': instance.parentId,
      'status': _$TodoStatusEnumMap[instance.status],
      'visibility': instance.visibility,
    };

const _$TodoStatusEnumMap = {
  TodoStatus.unscheduled: 'UNSCHEDULED',
  TodoStatus.scheduled: 'SCHEDULED',
  TodoStatus.done: 'DONE',
  TodoStatus.cancelled: 'CANCELLED',
  TodoStatus.$unknown: r'$unknown',
};
