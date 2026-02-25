// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'tag_stat.dart';

part 'todo_stats.freezed.dart';
part 'todo_stats.g.dart';

/// Todo 통계
@Freezed()
abstract class TodoStats with _$TodoStats {
  const factory TodoStats({
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'by_tag') required List<TagStat> byTag,
    @JsonKey(name: 'group_id') String? groupId,
  }) = _TodoStats;

  factory TodoStats.fromJson(Map<String, Object?> json) =>
      _$TodoStatsFromJson(json);
}
