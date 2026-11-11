import 'dart:math';

import 'package:momeet/shared/api/rest/export.dart';

/// 타이머의 표시 경과 시간
///
/// `elapsed_time`은 서버에 저장된 누적값이다. RUNNING이면 `started_at`(마지막 시작·재개 시각)부터
/// [now]까지를 더하고 서버처럼 `allocated_duration`을 넘지 않게 자른다. 그 외 상태는 저장값을 그대로 쓴다.
/// 저장값은 `allocated_duration`을 넘을 수 있고, Todo 집계도 저장값을 쓴다.
/// 화면을 그릴 때마다 다시 계산한다.
///
/// 테스트: test/shared/domain/timer_elapsed_test.dart
Duration displayElapsed(TimerRead timer, DateTime now) {
  if (timer.status != TimerStatus.running) {
    return Duration(seconds: timer.elapsedTime);
  }
  final startedAt = timer.startedAt;
  final running = startedAt == null
      ? 0
      : max(0, now.difference(startedAt).inSeconds);
  return Duration(
    seconds: min(timer.elapsedTime + running, timer.allocatedDuration),
  );
}

/// 타이머의 표시 남은 시간
///
/// `allocated_duration`에서 [displayElapsed]를 뺀 값이고, 0 아래로 내려가지 않는다.
Duration displayRemaining(TimerRead timer, DateTime now) {
  final remaining =
      Duration(seconds: timer.allocatedDuration) - displayElapsed(timer, now);
  return remaining.isNegative ? Duration.zero : remaining;
}

/// 집중 시간이 끝난 활성(RUNNING·PAUSED) 타이머인지
///
/// 서버는 시간이 끝난 RUNNING 타이머를 PAUSED로 돌려주고, 완료하거나 `allocated_duration`을 늘린 뒤에만 재개할 수 있다.
bool isTimeUp(TimerRead timer, DateTime now) =>
    (timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused) &&
    displayRemaining(timer, now) == Duration.zero;
