// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'schedule_read.dart';
import 'tag_read.dart';
import 'todo_include_reason.dart';
import 'todo_status.dart';
import 'visibility_level.dart';

part 'todo_read.freezed.dart';
part 'todo_read.g.dart';

/// Todo 조회 DTO
@Freezed()
abstract class TodoRead with _$TodoRead {
  const factory TodoRead({
    required String id,
    required String title,
    @JsonKey(name: 'tag_group_id') required String tagGroupId,
    required TodoStatus status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default([]) List<TagRead> tags,
    @Default([]) List<ScheduleRead> schedules,
    @JsonKey(name: 'include_reason')
    @Default(TodoIncludeReason.match)
    TodoIncludeReason includeReason,
    @JsonKey(name: 'is_shared') @Default(false) bool isShared,
    String? description,
    DateTime? deadline,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'owner_id') String? ownerId,
    @JsonKey(name: 'visibility_level') VisibilityLevel? visibilityLevel,
  }) = _TodoRead;

  factory TodoRead.fromJson(Map<String, Object?> json) =>
      _$TodoReadFromJson(json);
}
