// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TodoCreate _$TodoCreateFromJson(Map<String, dynamic> json) => _TodoCreate(
      title: json['title'] as String,
      tagGroupId: json['tag_group_id'] as String,
      status: json['status'] == null
          ? TodoStatus.unscheduled
          : TodoStatus.fromJson(json['status'] as String),
      description: json['description'] as String?,
      tagIds:
          (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      parentId: json['parent_id'] as String?,
      visibility: json['visibility'] == null
          ? null
          : VisibilitySettings.fromJson(
              json['visibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TodoCreateToJson(_TodoCreate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'tag_group_id': instance.tagGroupId,
      'status': _$TodoStatusEnumMap[instance.status],
      'description': instance.description,
      'tag_ids': instance.tagIds,
      'deadline': instance.deadline?.toIso8601String(),
      'parent_id': instance.parentId,
      'visibility': instance.visibility,
    };

const _$TodoStatusEnumMap = {
  TodoStatus.unscheduled: 'UNSCHEDULED',
  TodoStatus.scheduled: 'SCHEDULED',
  TodoStatus.done: 'DONE',
  TodoStatus.cancelled: 'CANCELLED',
  TodoStatus.$unknown: r'$unknown',
};
