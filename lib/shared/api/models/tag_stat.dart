// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_stat.freezed.dart';
part 'tag_stat.g.dart';

/// 태그별 통계
@Freezed()
abstract class TagStat with _$TagStat {
  const factory TagStat({
    @JsonKey(name: 'tag_id')
    required String tagId,
    @JsonKey(name: 'tag_name')
    required String tagName,
    required int count,
  }) = _TagStat;
  
  factory TagStat.fromJson(Map<String, Object?> json) => _$TagStatFromJson(json);
}
