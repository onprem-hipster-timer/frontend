// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimerRead _$TimerReadFromJson(Map<String, dynamic> json) => _TimerRead(
      id: json['id'] as String,
      allocatedDuration: (json['allocated_duration'] as num).toInt(),
      elapsedTime: (json['elapsed_time'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      pauseHistory: json['pause_history'] as List<dynamic>? ?? const [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => TagRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isShared: json['is_shared'] as bool? ?? false,
      scheduleId: json['schedule_id'] as String?,
      todoId: json['todo_id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      pausedAt: json['paused_at'] == null
          ? null
          : DateTime.parse(json['paused_at'] as String),
      endedAt: json['ended_at'] == null
          ? null
          : DateTime.parse(json['ended_at'] as String),
      schedule: json['schedule'] == null
          ? null
          : ScheduleRead.fromJson(json['schedule'] as Map<String, dynamic>),
      todo: json['todo'] == null
          ? null
          : TodoRead.fromJson(json['todo'] as Map<String, dynamic>),
      ownerId: json['owner_id'] as String?,
      visibilityLevel: json['visibility_level'] == null
          ? null
          : VisibilityLevel.fromJson(json['visibility_level'] as String),
    );

Map<String, dynamic> _$TimerReadToJson(_TimerRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'allocated_duration': instance.allocatedDuration,
      'elapsed_time': instance.elapsedTime,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'pause_history': instance.pauseHistory,
      'tags': instance.tags,
      'is_shared': instance.isShared,
      'schedule_id': instance.scheduleId,
      'todo_id': instance.todoId,
      'title': instance.title,
      'description': instance.description,
      'started_at': instance.startedAt?.toIso8601String(),
      'paused_at': instance.pausedAt?.toIso8601String(),
      'ended_at': instance.endedAt?.toIso8601String(),
      'schedule': instance.schedule,
      'todo': instance.todo,
      'owner_id': instance.ownerId,
      'visibility_level': _$VisibilityLevelEnumMap[instance.visibilityLevel],
    };

const _$VisibilityLevelEnumMap = {
  VisibilityLevel.private: 'private',
  VisibilityLevel.friends: 'friends',
  VisibilityLevel.selected: 'selected',
  VisibilityLevel.public: 'public',
  VisibilityLevel.$unknown: r'$unknown',
};
