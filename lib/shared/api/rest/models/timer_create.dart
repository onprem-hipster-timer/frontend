// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_create.freezed.dart';
part 'timer_create.g.dart';

/// 타이머 생성 DTO.
///
/// schedule_id와 todo_id 모두 Optional:.
/// - 둘 다 없으면: 독립 타이머.
/// - schedule_id만: Schedule에 연결된 타이머.
/// - todo_id만: Todo에 연결된 타이머.
/// - 둘 다 있으면: Schedule과 Todo 모두에 연결된 타이머.
@Freezed()
abstract class TimerCreate with _$TimerCreate {
  const factory TimerCreate({
    @JsonKey(name: 'allocated_duration') required int allocatedDuration,
    @JsonKey(name: 'schedule_id') String? scheduleId,
    @JsonKey(name: 'todo_id') String? todoId,
    String? title,
    String? description,
    @JsonKey(name: 'tag_ids') List<String>? tagIds,
  }) = _TimerCreate;

  factory TimerCreate.fromJson(Map<String, Object?> json) =>
      _$TimerCreateFromJson(json);
}
