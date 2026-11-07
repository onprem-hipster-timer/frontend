import 'dart:math';

import 'package:momeet/shared/api/rest/export.dart';

/// 타이머의 표시 경과 시간
///
/// `elapsed_time`은 서버에 저장된 누적값이다. RUNNING이면 `started_at`(마지막 시작·재개 시각)부터
/// [now]까지를 더하고, 그 외 상태는 저장값을 그대로 쓴다. 화면을 그릴 때마다 다시 계산한다.
///
/// 테스트: test/shared/domain/timer_elapsed_test.dart
Duration displayElapsed(TimerRead timer, DateTime now) {
  final startedAt = timer.startedAt;
  if (timer.status != TimerStatus.running || startedAt == null) {
    return Duration(seconds: timer.elapsedTime);
  }
  final running = now.difference(startedAt).inSeconds;
  return Duration(seconds: timer.elapsedTime + max(0, running));
}

/// 타이머의 표시 남은 시간
///
/// `allocated_duration`에서 [displayElapsed]를 뺀 값이고, 0 아래로 내려가지 않는다.
Duration displayRemaining(TimerRead timer, DateTime now) {
  final remaining =
      Duration(seconds: timer.allocatedDuration) - displayElapsed(timer, now);
  return remaining.isNegative ? Duration.zero : remaining;
}
