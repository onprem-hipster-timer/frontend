// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_group_read_with_tags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagGroupReadWithTags _$TagGroupReadWithTagsFromJson(
        Map<String, dynamic> json) =>
    _TagGroupReadWithTags(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      isTodoGroup: json['is_todo_group'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => TagRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      description: json['description'] as String?,
      goalRatios: (json['goal_ratios'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
    );

Map<String, dynamic> _$TagGroupReadWithTagsToJson(
        _TagGroupReadWithTags instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'is_todo_group': instance.isTodoGroup,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'tags': instance.tags,
      'description': instance.description,
      'goal_ratios': instance.goalRatios,
    };
