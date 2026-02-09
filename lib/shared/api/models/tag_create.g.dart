// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagCreate _$TagCreateFromJson(Map<String, dynamic> json) => _TagCreate(
      name: json['name'] as String,
      color: json['color'] as String,
      groupId: json['group_id'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$TagCreateToJson(_TagCreate instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'group_id': instance.groupId,
      'description': instance.description,
    };
