import 'package:flutter/foundation.dart';

/// 진행 중인 휴식. [endAt]에 끝나는 [total] 길이의 휴식
@immutable
class BreakSession {
  const BreakSession({required this.endAt, required this.total});

  final DateTime endAt;
  final Duration total;

  /// [now] 기준 남은 시간. 초 단위로 올리고 0 아래로 내려가지 않는다
  ///
  /// 올리므로 시작한 순간에 [total]을 보이고, [endAt]이 되어야 0이 된다.
  Duration remainingAt(DateTime now) {
    final micros = endAt.difference(now).inMicroseconds;
    if (micros <= 0) return Duration.zero;
    return Duration(
      seconds:
          (micros + Duration.microsecondsPerSecond - 1) ~/
          Duration.microsecondsPerSecond,
    );
  }
}
