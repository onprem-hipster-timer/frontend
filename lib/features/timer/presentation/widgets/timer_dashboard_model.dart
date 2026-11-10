import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

/// 대시보드가 그릴 값. 활성 타이머·휴식·내 타이머 목록과 서버 시각에서 한 번에 구한다
class TimerDashboardModel {
  TimerDashboardModel._({
    required this.activeTimer,
    required this.remaining,
    required this.breakSession,
    required this.breakRemaining,
    required this.myTimers,
    required this.breakBlocked,
    required this.pageNow,
    required this.timeUp,
  });

  /// [ref]로 필요한 값을 구독해 만든다. 반드시 build 안에서 부른다
  factory TimerDashboardModel.watch(WidgetRef ref) {
    final activeTimer = ref
        .watch(activeTimerProvider)
        .when(
          data: (timer) => timer,
          loading: () => null,
          error: (_, _) => null,
        );
    final now = ref.watch(serverClockProvider).now();
    final computed = activeTimer == null
        ? Duration.zero
        : displayRemaining(activeTimer, now);
    final remaining = ref
        .watch(timerTickerProvider)
        .when(
          data: (d) => d,
          loading: () => computed,
          error: (_, _) => computed,
        );

    final breakSession = ref.watch(breakTimerProvider);
    final breakComputed = breakSession?.remainingAt(now) ?? Duration.zero;
    final breakRemaining = ref
        .watch(breakTickerProvider)
        .when(
          data: (d) => d,
          loading: () => breakComputed,
          error: (_, _) => breakComputed,
        );
    final myTimers = ref.watch(myActiveTimersProvider).value ?? const [];
    final galleryShown = breakSession == null && myTimers.length >= 2;
    return TimerDashboardModel._(
      activeTimer: activeTimer,
      remaining: remaining,
      breakSession: breakSession,
      breakRemaining: breakRemaining,
      myTimers: myTimers,
      // 보이는 타이머가 일시정지여도 시간이 남은 채 실행 중인 다른 내 타이머가 있으면 휴식 버튼을 두지 않는다
      breakBlocked: blocksBreak(myTimers, now),
      // 갤러리의 다른 쪽도 서버 기준 시각으로 1초마다 센다
      pageNow: galleryShown ? ref.watch(serverNowProvider).value ?? now : now,
      timeUp:
          breakSession == null &&
          activeTimer != null &&
          (remaining == Duration.zero || isTimeUp(activeTimer, now)),
    );
  }

  final TimerRead? activeTimer;

  /// [activeTimer]의 남은 시간
  final Duration remaining;

  /// 진행 중인 휴식. 휴식은 활성 타이머보다 먼저 보인다
  final BreakSession? breakSession;
  final Duration breakRemaining;
  final List<TimerRead> myTimers;
  final bool breakBlocked;

  /// 갤러리의 다른 쪽 다이얼이 쓰는 시각
  final DateTime pageNow;

  /// [activeTimer]의 시간이 끝났는지 (휴식 중이면 false)
  final bool timeUp;

  bool get onBreak => breakSession != null;
  bool get breakOver => onBreak && breakRemaining == Duration.zero;
  bool get idle => !onBreak && activeTimer == null;

  /// 활성 타이머가 둘 이상이면 다이얼 자리에 갤러리를 둔다
  bool get galleryShown => !onBreak && myTimers.length >= 2;

  /// 다이얼 아래 상태 문구
  String? get caption => onBreak
      ? (breakOver ? '휴식 종료' : null)
      : timeUp
      ? '시간 종료'
      : activeTimer?.status == TimerStatus.paused
      ? '일시정지'
      : null;

  /// [timer] 다이얼 색: 시간이 끝났으면 오류색, 일시정지면 흐린 주색
  static Color timerColor(
    ColorScheme colorScheme,
    TimerRead timer, {
    required bool timeUp,
  }) => timeUp
      ? colorScheme.error
      : timer.status == TimerStatus.paused
      ? colorScheme.primary.withValues(alpha: 0.5)
      : colorScheme.primary;

  /// 큰 다이얼 색. 휴식(대기 중 휴식을 고른 때 포함)은 3차색
  Color dialColor(ColorScheme colorScheme, {required bool breakSelected}) {
    final activeTimer = this.activeTimer;
    if (onBreak || (idle && breakSelected)) return colorScheme.tertiary;
    if (activeTimer == null) return colorScheme.primary;
    return timerColor(colorScheme, activeTimer, timeUp: timeUp);
  }
}
