import 'package:freezed_annotation/freezed_annotation.dart';

import 'timer_ws_event.dart';

// ignore_for_file: invalid_annotation_target

part 'timer_ws_connected.freezed.dart';
part 'timer_ws_connected.g.dart';

/// 연결 성공 (connected)
@Freezed(fromJson: true)
abstract class TimerWsConnected extends TimerWsEvent with _$TimerWsConnected {
  const TimerWsConnected._();
  const factory TimerWsConnected({
    @JsonKey(name: 'user_id') required String userId,
    required String message,
  }) = _TimerWsConnected;

  factory TimerWsConnected.fromJson(Map<String, Object?> json) =>
      _$TimerWsConnectedFromJson(json);
}
