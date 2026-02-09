// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_group_update.freezed.dart';
part 'tag_group_update.g.dart';

/// 태그 그룹 업데이트 DTO
@Freezed()
abstract class TagGroupUpdate with _$TagGroupUpdate {
  const factory TagGroupUpdate({
    String? name,
    String? color,
    String? description,
    @JsonKey(name: 'goal_ratios')
    Map<String, num>? goalRatios,
    @JsonKey(name: 'is_todo_group')
    bool? isTodoGroup,
  }) = _TagGroupUpdate;
  
  factory TagGroupUpdate.fromJson(Map<String, Object?> json) => _$TagGroupUpdateFromJson(json);
}
