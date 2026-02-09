// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_group_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagGroupRead _$TagGroupReadFromJson(Map<String, dynamic> json) =>
    _TagGroupRead(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isTodoGroup: json['is_todo_group'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
      goalRatios: (json['goal_ratios'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
    );

Map<String, dynamic> _$TagGroupReadToJson(_TagGroupRead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'is_todo_group': instance.isTodoGroup,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'description': instance.description,
      'goal_ratios': instance.goalRatios,
    };
