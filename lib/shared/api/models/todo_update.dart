// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'todo_status.dart';
import 'visibility_settings.dart';

part 'todo_update.freezed.dart';
part 'todo_update.g.dart';

/// Todo 업데이트 DTO
@Freezed()
abstract class TodoUpdate with _$TodoUpdate {
  const factory TodoUpdate({
    String? title,
    String? description,
    @JsonKey(name: 'tag_group_id')
    String? tagGroupId,
    @JsonKey(name: 'tag_ids')
    List<String>? tagIds,
    DateTime? deadline,
    @JsonKey(name: 'parent_id')
    String? parentId,
    TodoStatus? status,
    VisibilitySettings? visibility,
  }) = _TodoUpdate;
  
  factory TodoUpdate.fromJson(Map<String, Object?> json) => _$TodoUpdateFromJson(json);
}
