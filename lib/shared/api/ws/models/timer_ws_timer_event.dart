import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/shared/api/rest/models/timer_read.dart';

import 'timer_ws_event.dart';

// ignore_for_file: invalid_annotation_target

part 'timer_ws_timer_event.freezed.dart';
part 'timer_ws_timer_event.g.dart';

/// 타이머 변경 이벤트 (timer.created / timer.updated / timer.deleted)
///
/// [fromUser]는 변경을 일으킨 사용자의 sub다. 시각은 모두 UTC다.
@Freezed(fromJson: true)
abstract class TimerWsTimerEvent extends TimerWsEvent with _$TimerWsTimerEvent {
  const TimerWsTimerEvent._();
  const factory TimerWsTimerEvent({
    required String id,
    required String type,
    @JsonKey(name: 'from_user') String? fromUser,
    required DateTime timestamp,
    required TimerWsEventPayload payload,
  }) = _TimerWsTimerEvent;

  factory TimerWsTimerEvent.fromJson(Map<String, Object?> json) =>
      _$TimerWsTimerEventFromJson(json);
}

/// 이벤트 payload. `timer.deleted`면 [timer]가 null이고 [timerId]로 식별한다.
@Freezed(fromJson: true)
abstract class TimerWsEventPayload with _$TimerWsEventPayload {
  const factory TimerWsEventPayload({
    required String action,
    @JsonKey(name: 'actor_name') String? actorName,
    TimerRead? timer,
    @JsonKey(name: 'timer_id') String? timerId,
  }) = _TimerWsEventPayload;

  factory TimerWsEventPayload.fromJson(Map<String, Object?> json) =>
      _$TimerWsEventPayloadFromJson(json);
}
