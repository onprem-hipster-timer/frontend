import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'timer_create_payload.freezed.dart';
part 'timer_create_payload.g.dart';

/// timer.create 페이로드 (클라이언트 → 서버)
@Freezed()
abstract class TimerCreatePayload with _$TimerCreatePayload {
  const factory TimerCreatePayload({
    @JsonKey(name: 'allocated_duration') int? allocatedDuration,
    String? title,
    String? description,
    @JsonKey(name: 'schedule_id') String? scheduleId,
    @JsonKey(name: 'todo_id') String? todoId,
    @JsonKey(name: 'tag_ids') List<String>? tagIds,
  }) = _TimerCreatePayload;

  factory TimerCreatePayload.fromJson(Map<String, Object?> json) =>
      _$TimerCreatePayloadFromJson(json);
}
