// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_stat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagStat _$TagStatFromJson(Map<String, dynamic> json) => _TagStat(
      tagId: json['tag_id'] as String,
      tagName: json['tag_name'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$TagStatToJson(_TagStat instance) => <String, dynamic>{
      'tag_id': instance.tagId,
      'tag_name': instance.tagName,
      'count': instance.count,
    };
