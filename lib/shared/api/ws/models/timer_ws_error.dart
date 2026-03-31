import 'package:freezed_annotation/freezed_annotation.dart';

import 'timer_ws_event.dart';

part 'timer_ws_error.freezed.dart';
part 'timer_ws_error.g.dart';

/// 에러 (error)
@Freezed(fromJson: true)
abstract class TimerWsError extends TimerWsEvent with _$TimerWsError {
  const TimerWsError._();
  const factory TimerWsError({required String code, required String message}) =
      _TimerWsError;

  factory TimerWsError.fromJson(Map<String, Object?> json) =>
      _$TimerWsErrorFromJson(json);
}
