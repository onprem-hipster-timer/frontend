import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/shared/api/rest/models/timer_read.dart';

import 'timer_ws_event.dart';

part 'timer_ws_timer_completed.freezed.dart';
part 'timer_ws_timer_completed.g.dart';

/// 타이머 완료됨 (timer.completed)
@Freezed(fromJson: true)
abstract class TimerWsTimerCompleted extends TimerWsEvent
    with _$TimerWsTimerCompleted {
  const TimerWsTimerCompleted._();
  const factory TimerWsTimerCompleted({
    required TimerRead timer,
  }) = _TimerWsTimerCompleted;

  factory TimerWsTimerCompleted.fromJson(Map<String, Object?> json) =>
      _$TimerWsTimerCompletedFromJson(json);
}
