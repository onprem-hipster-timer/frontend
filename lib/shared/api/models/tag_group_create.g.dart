// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_group_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagGroupCreate _$TagGroupCreateFromJson(Map<String, dynamic> json) =>
    _TagGroupCreate(
      name: json['name'] as String,
      color: json['color'] as String,
      isTodoGroup: json['is_todo_group'] as bool? ?? false,
      description: json['description'] as String?,
      goalRatios: (json['goal_ratios'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
    );

Map<String, dynamic> _$TagGroupCreateToJson(_TagGroupCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'is_todo_group': instance.isTodoGroup,
      'description': instance.description,
      'goal_ratios': instance.goalRatios,
    };
