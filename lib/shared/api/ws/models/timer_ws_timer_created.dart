import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/shared/api/rest/models/timer_read.dart';

import 'timer_ws_event.dart';

part 'timer_ws_timer_created.freezed.dart';
part 'timer_ws_timer_created.g.dart';

/// 타이머 생성됨 (timer.created)
@Freezed(fromJson: true)
abstract class TimerWsTimerCreated extends TimerWsEvent
    with _$TimerWsTimerCreated {
  const TimerWsTimerCreated._();
  const factory TimerWsTimerCreated({
    required TimerRead timer,
    String? action,
  }) = _TimerWsTimerCreated;

  factory TimerWsTimerCreated.fromJson(Map<String, Object?> json) =>
      _$TimerWsTimerCreatedFromJson(json);
}
