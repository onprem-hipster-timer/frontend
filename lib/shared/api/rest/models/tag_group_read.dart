// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_group_read.freezed.dart';
part 'tag_group_read.g.dart';

/// 태그 그룹 조회 DTO
@Freezed()
abstract class TagGroupRead with _$TagGroupRead {
  const factory TagGroupRead({
    required String id,
    required String name,
    required String color,
    @JsonKey(name: 'is_todo_group') required bool isTodoGroup,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    String? description,
    @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios,
  }) = _TagGroupRead;

  factory TagGroupRead.fromJson(Map<String, Object?> json) =>
      _$TagGroupReadFromJson(json);
}
