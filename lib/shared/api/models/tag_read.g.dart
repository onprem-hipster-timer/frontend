// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_read.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagRead _$TagReadFromJson(Map<String, dynamic> json) => _TagRead(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      groupId: json['group_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$TagReadToJson(_TagRead instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'group_id': instance.groupId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'description': instance.description,
    };
