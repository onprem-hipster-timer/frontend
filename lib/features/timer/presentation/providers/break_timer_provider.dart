import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

part 'break_timer_provider.g.dart';

/// 새 휴식의 기본 길이
const defaultBreakDuration = Duration(minutes: 5);

/// 휴식 시간을 재는 기기 시각. 테스트에서 바꾼다
@Riverpod(keepAlive: true)
DateTime Function() breakClock(Ref ref) => DateTime.now;

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

/// 휴식 카운트다운
///
/// 기기 안에서만 센다. 서버에 보내지 않으므로 타이머 목록·친구 알림에 나오지 않는다.
/// 활성 타이머가 실행 중(RUNNING)이면 휴식이 없다. 휴식 중에 활성 타이머가 실행 중이 되면 바로 끝낸다.
/// 일시정지한 타이머는 휴식을 끝내지 않는다.
///
/// 테스트: test/features/timer/presentation/providers/break_timer_provider_test.dart
@Riverpod(keepAlive: true)
class BreakTimer extends _$BreakTimer {
  /// 휴식 중에만 두는 활성 타이머 구독
  ///
  /// 이 provider를 보는 화면이 없으면(다른 탭) provider 안의 `ref.listen`은 쉬어서 그사이 실행된 타이머를
  /// 놓치므로 컨테이너에서 듣는다.
  ProviderSubscription<AsyncValue<TimerRead?>>? _activeTimer;

  @override
  BreakSession? build() => null;

  /// [total] 길이의 휴식을 시작한다. 진행 중인 휴식은 새 휴식으로 바꾼다.
  ///
  /// 활성 타이머가 실행 중이면 휴식을 두지 않는다.
  void start(Duration total) {
    final activeTimer = _activeTimer ??= ref.container.listen(
      activeTimerProvider,
      (_, next) => _endIfRunning(next),
    );
    state = BreakSession(
      endAt: ref.read(breakClockProvider)().add(total),
      total: total,
    );
    _endIfRunning(activeTimer.read());
  }

  /// 휴식을 끝낸다
  void end() {
    _activeTimer?.close();
    _activeTimer = null;
    state = null;
  }

  void _endIfRunning(AsyncValue<TimerRead?> activeTimer) {
    if (activeTimer.value?.status == TimerStatus.running) end();
  }
}

/// 휴식의 남은 시간 ([BreakSession.remainingAt])을 바로 한 번, 이후 1초마다 낸다. 휴식이 없으면 Duration.zero
@riverpod
Stream<Duration> breakTicker(Ref ref) async* {
  final session = ref.watch(breakTimerProvider);
  final now = ref.watch(breakClockProvider);
  if (session == null) {
    yield Duration.zero;
    return;
  }

  yield session.remainingAt(now());
  // yield*는 구독을 취소하면 바로 틱을 멈춘다
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => session.remainingAt(now()),
  );
}
