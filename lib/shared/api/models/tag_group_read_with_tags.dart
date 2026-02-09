// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'tag_read.dart';

part 'tag_group_read_with_tags.freezed.dart';
part 'tag_group_read_with_tags.g.dart';

/// 태그 그룹 조회 DTO (태그 포함)
@Freezed()
abstract class TagGroupReadWithTags with _$TagGroupReadWithTags {
  const factory TagGroupReadWithTags({
    required String id,
    required String name,
    required String color,
    @JsonKey(name: 'is_todo_group')
    required bool isTodoGroup,
    @JsonKey(name: 'created_at')
    required DateTime createdAt,
    @JsonKey(name: 'updated_at')
    required DateTime updatedAt,
    @Default([])
    List<TagRead> tags,
    String? description,
    @JsonKey(name: 'goal_ratios')
    Map<String, num>? goalRatios,
  }) = _TagGroupReadWithTags;
  
  factory TagGroupReadWithTags.fromJson(Map<String, Object?> json) => _$TagGroupReadWithTagsFromJson(json);
}
