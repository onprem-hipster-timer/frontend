// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TodoStats _$TodoStatsFromJson(Map<String, dynamic> json) => _TodoStats(
      totalCount: (json['total_count'] as num).toInt(),
      byTag: (json['by_tag'] as List<dynamic>)
          .map((e) => TagStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupId: json['group_id'] as String?,
    );

Map<String, dynamic> _$TodoStatsToJson(_TodoStats instance) =>
    <String, dynamic>{
      'total_count': instance.totalCount,
      'by_tag': instance.byTag,
      'group_id': instance.groupId,
    };
