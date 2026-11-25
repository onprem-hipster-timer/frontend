import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/utils/timer_actions.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_controls.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_model.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_view.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

export 'package:momeet/features/timer/presentation/widgets/timer_dashboard_view.dart'
    show timerWideLayoutMinWidth;

/// 타이머 대시보드. 모양은 [TimerDashboardView]
///
/// 휴식 중이면 휴식을, 아니면 고른 활성 타이머([activeTimerProvider])를 보여 줍니다.
/// 갤러리에서 넘긴 쪽의 타이머를 고르고, 작업 제목 앞에서 고른 할 일 상태를 저장합니다.
/// 휴식은 서버에 보내지 않고 바로 시작합니다.
class TimerDashboard extends ConsumerWidget {
  const TimerDashboard({
    super.key,
    this.focusLeading,
    this.focusActions = const [],
  });

  /// 집중 보기에서 작업명 줄 왼쪽에 두는 것(화면 이동 ☰ 등). 집중 보기는 앱바 없이 이 줄이 맨 위다
  final Widget? focusLeading;

  /// 집중 보기에서 작업명 줄 오른쪽에 두는 버튼들
  final List<Widget> focusActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = _watchModel(ref);
    final activeTimer = model.activeTimer;
    return TimerDashboardView(
      model: model,
      focusLeading: focusLeading,
      focusActions: focusActions,
      onFocusTimer: (timerId) =>
          ref.read(focusedTimerIdProvider.notifier).focus(timerId),
      onTodoStatusSelected: (status) async {
        final todo = activeTimer?.todo;
        if (todo == null || status == todo.status) return;
        final updated = await updateTodoMutation.run(
          ref,
          (tsx) => tsx
              .get(todoMutationsProvider.notifier)
              .changeStatus(todo.id, status),
        );
        if (!context.mounted) return;
        ref.read(myActiveTimersProvider.notifier).updateTodo(updated);
      },
      addTimerBuilder: (initialDuration, icon) =>
          _AddTimerChip(initialDuration: initialDuration, icon: icon),
      controlsBuilder:
          ({
            required breakSelected,
            required pendingDuration,
            required pendingBreakDuration,
          }) => TimerDashboardControls(
            onBreak: model.onBreak,
            breakOver: model.breakOver,
            activeTimer: activeTimer,
            timeUp: model.timeUp,
            breakSelected: breakSelected,
            breakBlocked: model.breakBlocked,
            pendingDuration: pendingDuration,
            pendingBreakDuration: pendingBreakDuration,
          ),
    );
  }
}

/// [ref]로 대시보드가 그릴 값을 구독해 만든다. 반드시 build 안에서 부른다
TimerDashboardModel _watchModel(WidgetRef ref) {
  final activeTimer = ref
      .watch(activeTimerProvider)
      .whenOrNull(data: (timer) => timer);
  final now = ref.watch(serverClockProvider).now();
  final computed = activeTimer == null
      ? Duration.zero
      : displayRemaining(activeTimer, now);
  final remaining = ref
      .watch(timerTickerProvider)
      .when(data: (d) => d, loading: () => computed, error: (_, _) => computed);

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
  return TimerDashboardModel(
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

/// 다른 타이머가 도는 중에도 새 작업을 시작하는 칩
class _AddTimerChip extends ConsumerWidget {
  const _AddTimerChip({required this.initialDuration, this.icon = false});

  final Duration initialDuration;

  /// 글자 없이 아이콘 버튼으로 둔다(집중 보기)
  final bool icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPressed = ref.watch(timerControllerProvider).isLoading
        ? null
        : () => startTimerFromSheet(
            context,
            ref,
            initialDuration: initialDuration,
          );
    if (icon) {
      return IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: '새 ${Terms.timer}',
        onPressed: onPressed,
      );
    }
    return ActionChip(
      avatar: const Icon(Icons.add),
      label: const Text('새 ${Terms.timer}'),
      onPressed: onPressed,
    );
  }
}
