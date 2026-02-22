import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'timer_sync_payload.freezed.dart';
part 'timer_sync_payload.g.dart';

/// timer.sync 페이로드 (클라이언트 → 서버)
@Freezed()
abstract class TimerSyncPayload with _$TimerSyncPayload {
  const factory TimerSyncPayload({
    @Default('active') String scope,
    @JsonKey(name: 'timer_id') String? timerId,
  }) = _TimerSyncPayload;

  factory TimerSyncPayload.fromJson(Map<String, Object?> json) =>
      _$TimerSyncPayloadFromJson(json);
}
