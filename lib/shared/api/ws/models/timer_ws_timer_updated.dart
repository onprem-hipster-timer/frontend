import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/shared/api/rest/models/timer_read.dart';

import 'timer_ws_event.dart';

part 'timer_ws_timer_updated.freezed.dart';
part 'timer_ws_timer_updated.g.dart';

/// 타이머 수정됨 (timer.updated)
///
/// `action: 'sync'`(timer.sync 단건 조회 응답)에서 대상 타이머가 없으면
/// 백엔드가 `timer: null`을 보낼 수 있어 [timer]는 nullable입니다.
/// 수신 처리 시 [timer] 접근 전 null guard가 필요합니다.
@Freezed(fromJson: true)
abstract class TimerWsTimerUpdated extends TimerWsEvent
    with _$TimerWsTimerUpdated {
  const TimerWsTimerUpdated._();
  const factory TimerWsTimerUpdated({TimerRead? timer, String? action}) =
      _TimerWsTimerUpdated;

  factory TimerWsTimerUpdated.fromJson(Map<String, Object?> json) =>
      _$TimerWsTimerUpdatedFromJson(json);
}
