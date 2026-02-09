// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimerUpdate _$TimerUpdateFromJson(Map<String, dynamic> json) => _TimerUpdate(
      title: json['title'] as String?,
      description: json['description'] as String?,
      tagIds:
          (json['tag_ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
      todoId: json['todo_id'] as String?,
      scheduleId: json['schedule_id'] as String?,
      visibility: json['visibility'] == null
          ? null
          : VisibilitySettings.fromJson(
              json['visibility'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TimerUpdateToJson(_TimerUpdate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'tag_ids': instance.tagIds,
      'todo_id': instance.todoId,
      'schedule_id': instance.scheduleId,
      'visibility': instance.visibility,
    };
