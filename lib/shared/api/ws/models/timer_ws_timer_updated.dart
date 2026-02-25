import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/shared/api/rest/models/timer_read.dart';

import 'timer_ws_event.dart';

part 'timer_ws_timer_updated.freezed.dart';
part 'timer_ws_timer_updated.g.dart';

/// 타이머 수정됨 (timer.updated)
@Freezed(fromJson: true)
abstract class TimerWsTimerUpdated extends TimerWsEvent
    with _$TimerWsTimerUpdated {
  const TimerWsTimerUpdated._();
  const factory TimerWsTimerUpdated({
    required TimerRead timer,
    String? action,
  }) = _TimerWsTimerUpdated;

  factory TimerWsTimerUpdated.fromJson(Map<String, Object?> json) =>
      _$TimerWsTimerUpdatedFromJson(json);
}
