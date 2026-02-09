// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_group_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagGroupUpdate _$TagGroupUpdateFromJson(Map<String, dynamic> json) =>
    _TagGroupUpdate(
      name: json['name'] as String?,
      color: json['color'] as String?,
      description: json['description'] as String?,
      goalRatios: (json['goal_ratios'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as num),
      ),
      isTodoGroup: json['is_todo_group'] as bool?,
    );

Map<String, dynamic> _$TagGroupUpdateToJson(_TagGroupUpdate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'description': instance.description,
      'goal_ratios': instance.goalRatios,
      'is_todo_group': instance.isTodoGroup,
    };
