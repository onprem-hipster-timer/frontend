import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'timer_id_payload.freezed.dart';
part 'timer_id_payload.g.dart';

/// timer.pause / timer.resume / timer.stop 공통 페이로드 (클라이언트 → 서버)
@Freezed()
abstract class TimerIdPayload with _$TimerIdPayload {
  const factory TimerIdPayload({
    @JsonKey(name: 'timer_id') required String timerId,
  }) = _TimerIdPayload;

  factory TimerIdPayload.fromJson(Map<String, Object?> json) =>
      _$TimerIdPayloadFromJson(json);
}
