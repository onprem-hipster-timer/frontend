// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'visibility_settings.dart';

part 'timer_update.freezed.dart';
part 'timer_update.g.dart';

/// 타이머 업데이트 DTO.
///
/// todo_id, schedule_id 필드 동작:.
/// - 필드가 요청에 포함되지 않음 (undefined): 기존 값 유지.
/// - 필드가 UUID 값: 해당 ID로 연결 변경.
/// - 필드가 null: 연결 해제.
///
/// Note: 자동 연결 기능은 적용되지 않음 (명시적 변경만 수행).
@Freezed()
abstract class TimerUpdate with _$TimerUpdate {
  const factory TimerUpdate({
    String? title,
    String? description,
    @JsonKey(name: 'tag_ids')
    List<String>? tagIds,
    @JsonKey(name: 'todo_id')
    String? todoId,
    @JsonKey(name: 'schedule_id')
    String? scheduleId,
    VisibilitySettings? visibility,
  }) = _TimerUpdate;
  
  factory TimerUpdate.fromJson(Map<String, Object?> json) => _$TimerUpdateFromJson(json);
}
