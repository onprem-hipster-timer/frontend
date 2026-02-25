import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:momeet/shared/api/rest/models/timer_read.dart';

import 'timer_ws_event.dart';

part 'timer_ws_sync_result.freezed.dart';
part 'timer_ws_sync_result.g.dart';

/// 활성 타이머 동기화 결과 (timer.sync_result / timer.synced)
@Freezed(fromJson: true)
abstract class TimerWsSyncResult extends TimerWsEvent with _$TimerWsSyncResult {
  const TimerWsSyncResult._();
  const factory TimerWsSyncResult({
    required List<TimerRead> timers,
    required int count,
  }) = _TimerWsSyncResult;

  factory TimerWsSyncResult.fromJson(Map<String, Object?> json) =>
      _$TimerWsSyncResultFromJson(json);
}
