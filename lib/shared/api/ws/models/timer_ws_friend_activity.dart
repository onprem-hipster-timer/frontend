import 'package:freezed_annotation/freezed_annotation.dart';

import 'timer_ws_event.dart';

// ignore_for_file: invalid_annotation_target

part 'timer_ws_friend_activity.freezed.dart';
part 'timer_ws_friend_activity.g.dart';

/// 친구 활동 알림 (timer.friend_activity)
@Freezed(fromJson: true)
abstract class TimerWsFriendActivity extends TimerWsEvent
    with _$TimerWsFriendActivity {
  const TimerWsFriendActivity._();
  const factory TimerWsFriendActivity({
    @JsonKey(name: 'friend_id') required String friendId,
    required String action,
    @JsonKey(name: 'timer_id') required String timerId,
    @JsonKey(name: 'timer_title') String? timerTitle,
  }) = _TimerWsFriendActivity;

  factory TimerWsFriendActivity.fromJson(Map<String, Object?> json) =>
      _$TimerWsFriendActivityFromJson(json);
}
