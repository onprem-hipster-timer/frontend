// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TodoRead _$TodoReadFromJson(Map<String, dynamic> json) => _TodoRead(
      id: json['id'] as String,
      title: json['title'] as String,
      tagGroupId: json['tag_group_id'] as String,
      status: TodoStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => TagRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((e) => ScheduleRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      includeReason: json['include_reason'] == null
          ? TodoIncludeReason.match
          : TodoIncludeReason.fromJson(json['include_reason'] as String),
      isShared: json['is_shared'] as bool? ?? false,
      description: json['description'] as String?,
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      parentId: json['parent_id'] as String?,
      ownerId: json['owner_id'] as String?,
      visibilityLevel: json['visibility_level'] == null
          ? null
          : VisibilityLevel.fromJson(json['visibility_level'] as String),
    );

Map<String, dynamic> _$TodoReadToJson(_TodoRead instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tag_group_id': instance.tagGroupId,
      'status': _$TodoStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'tags': instance.tags,
      'schedules': instance.schedules,
      'include_reason': _$TodoIncludeReasonEnumMap[instance.includeReason]!,
      'is_shared': instance.isShared,
      'description': instance.description,
      'deadline': instance.deadline?.toIso8601String(),
      'parent_id': instance.parentId,
      'owner_id': instance.ownerId,
      'visibility_level': _$VisibilityLevelEnumMap[instance.visibilityLevel],
    };

const _$TodoStatusEnumMap = {
  TodoStatus.unscheduled: 'UNSCHEDULED',
  TodoStatus.scheduled: 'SCHEDULED',
  TodoStatus.done: 'DONE',
  TodoStatus.cancelled: 'CANCELLED',
  TodoStatus.$unknown: r'$unknown',
};

const _$TodoIncludeReasonEnumMap = {
  TodoIncludeReason.match: 'MATCH',
  TodoIncludeReason.ancestor: 'ANCESTOR',
  TodoIncludeReason.$unknown: r'$unknown',
};

const _$VisibilityLevelEnumMap = {
  VisibilityLevel.private: 'private',
  VisibilityLevel.friends: 'friends',
  VisibilityLevel.selected: 'selected',
  VisibilityLevel.public: 'public',
  VisibilityLevel.$unknown: r'$unknown',
};
