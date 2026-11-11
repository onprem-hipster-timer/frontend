import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

part 'break_timer_provider.g.dart';

/// 새 휴식의 기본 길이
const defaultBreakDuration = Duration(minutes: 5);

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

/// [timers] 중 시간이 남은 실행 중(RUNNING) 타이머가 있어 휴식을 둘 수 없는지. [now]는 서버 기준 시각이다
///
/// 시간이 끝난 RUNNING 타이머는 서버가 일시정지로 돌려주므로 휴식을 막지 않는다.
bool blocksBreak(Iterable<TimerRead> timers, DateTime now) => timers.any(
  (timer) => timer.status == TimerStatus.running && !isTimeUp(timer, now),
);

/// 휴식 카운트다운
///
/// 기기 안에서만 센다. 서버에 보내지 않으므로 타이머 목록·친구 알림에 나오지 않는다.
/// 타이머와 같은 서버 기준 시각([serverClockProvider])으로 끝나는 시각과 남은 시간을 센다.
/// 내 활성 타이머 중 하나라도 시간이 남은 채 실행 중(RUNNING)이면 휴식이 없다([blocksBreak]).
/// 휴식 중에 그런 타이머가 생기면 바로 끝낸다. 일시정지한 타이머는 휴식을 끝내지 않는다.
/// 로그인한 사용자가 바뀌면(로그아웃 포함) 휴식을 버린다.
///
/// 테스트: test/features/timer/presentation/providers/break_timer_provider_test.dart
@Riverpod(keepAlive: true)
class BreakTimer extends _$BreakTimer {
  /// 휴식 중에만 두는 내 활성 타이머 구독
  ///
  /// 이 provider를 보는 화면이 없으면(다른 탭) provider 안의 `ref.listen`은 쉬어서 그사이 실행된 타이머를
  /// 놓치므로 컨테이너에서 듣는다. 사용자가 바뀌면 닫아 이전 사용자의 타이머를 붙잡지 않는다.
  ProviderSubscription<AsyncValue<List<TimerRead>>>? _timers;

  @override
  BreakSession? build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    ref.onDispose(_unsubscribe);
    return null;
  }

  /// [total] 길이의 휴식을 시작한다. 진행 중인 휴식은 새 휴식으로 바꾼다.
  ///
  /// 시간이 남은 실행 중 타이머가 있으면 휴식을 두지 않는다.
  void start(Duration total) {
    final timers = _timers ??= ref.container.listen(
      myActiveTimersProvider,
      (_, next) => _endIfBlocked(next),
    );
    state = BreakSession(
      endAt: ref.read(serverClockProvider).now().add(total),
      total: total,
    );
    _endIfBlocked(timers.read());
  }

  /// 휴식을 끝낸다
  void end() {
    _unsubscribe();
    state = null;
  }

  void _unsubscribe() {
    _timers?.close();
    _timers = null;
  }

  void _endIfBlocked(AsyncValue<List<TimerRead>> timers) {
    final now = ref.read(serverClockProvider).now();
    if (blocksBreak(timers.value ?? const [], now)) end();
  }
}

/// 휴식의 남은 시간 ([BreakSession.remainingAt], 서버 기준 시각)을 바로 한 번, 이후 1초마다 낸다. 휴식이 없으면 Duration.zero
@riverpod
Stream<Duration> breakTicker(Ref ref) async* {
  final session = ref.watch(breakTimerProvider);
  final clock = ref.watch(serverClockProvider);
  if (session == null) {
    yield Duration.zero;
    return;
  }

  yield session.remainingAt(clock.now());
  // yield*는 구독을 취소하면 바로 틱을 멈춘다
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (_) => session.remainingAt(clock.now()),
  );
}
