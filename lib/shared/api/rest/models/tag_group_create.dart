// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_group_create.freezed.dart';
part 'tag_group_create.g.dart';

/// 태그 그룹 생성 DTO
@Freezed()
abstract class TagGroupCreate with _$TagGroupCreate {
  const factory TagGroupCreate({
    required String name,
    required String color,
    @JsonKey(name: 'is_todo_group') @Default(false) bool isTodoGroup,
    String? description,
    @JsonKey(name: 'goal_ratios') Map<String, num>? goalRatios,
  }) = _TagGroupCreate;

  factory TagGroupCreate.fromJson(Map<String, Object?> json) =>
      _$TagGroupCreateFromJson(json);
}
