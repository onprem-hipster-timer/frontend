// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'todo_status.dart';
import 'visibility_settings.dart';

part 'todo_create.freezed.dart';
part 'todo_create.g.dart';

/// Todo 생성 DTO
@Freezed()
abstract class TodoCreate with _$TodoCreate {
  const factory TodoCreate({
    required String title,
    @JsonKey(name: 'tag_group_id') required String tagGroupId,
    @Default(TodoStatus.unscheduled) TodoStatus? status,
    String? description,
    @JsonKey(name: 'tag_ids') List<String>? tagIds,
    DateTime? deadline,
    @JsonKey(name: 'parent_id') String? parentId,
    VisibilitySettings? visibility,
  }) = _TodoCreate;

  factory TodoCreate.fromJson(Map<String, Object?> json) =>
      _$TodoCreateFromJson(json);
}
