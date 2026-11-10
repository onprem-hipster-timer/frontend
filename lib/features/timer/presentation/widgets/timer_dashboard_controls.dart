import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/utils/timer_actions.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_control_button.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 대시보드 맨 아래의 조작 버튼
///
/// 휴식 중이면 휴식 끝내기(끝났으면 확인)를, 아니면 [TimerControlButton]을 둔다.
/// 일시정지·재개·연장은 그 타이머를 대시보드가 계속 보이게 고른다.
class TimerDashboardControls extends ConsumerWidget {
  const TimerDashboardControls({
    super.key,
    required this.onBreak,
    required this.breakOver,
    required this.activeTimer,
    required this.timeUp,
    required this.breakSelected,
    required this.breakBlocked,
    required this.pendingDuration,
    required this.pendingBreakDuration,
  });

  /// 휴식 중인지
  final bool onBreak;
  final bool breakOver;
  final TimerRead? activeTimer;
  final bool timeUp;
  final bool breakSelected;

  /// 시간이 남은 채 도는 내 타이머가 있어 휴식을 시작할 수 없는지
  final bool breakBlocked;
  final Duration pendingDuration;
  final Duration pendingBreakDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    if (onBreak) {
      return FloatingActionButton(
        onPressed: () => ref.read(breakTimerProvider.notifier).end(),
        tooltip: breakOver ? '확인' : '휴식 끝내기',
        backgroundColor: colorScheme.tertiary,
        child: Icon(
          breakOver ? Icons.check : Icons.stop,
          color: colorScheme.onTertiary,
        ),
      );
    }
    final controller = ref.read(timerControllerProvider.notifier);
    final id = activeTimer?.id;
    return TimerControlButton(
      activeTimer: activeTimer,
      starting: ref.watch(timerControllerProvider).isLoading,
      timeUp: timeUp,
      breakSelected: breakSelected,
      onStart: () =>
          startTimerFromSheet(context, ref, initialDuration: pendingDuration),
      onStartBreak: breakBlocked
          ? null
          : () => ref
                .read(breakTimerProvider.notifier)
                .start(pendingBreakDuration),
      onStop: () => _stop(context, ref),
      onPause: () =>
          _run(context, ref, '일시정지', () => controller.pauseTimer(timerId: id!)),
      onResume: () =>
          _run(context, ref, '재개', () => controller.resumeTimer(timerId: id!)),
      onExtend: () => _run(
        context,
        ref,
        '연장',
        () => controller.extendTimer(timerId: id!, by: timerExtendStep),
      ),
    );
  }

  /// 보이는 타이머를 묶어 두고 [command]를 보낸다. 명령으로 기본 타이머가 바뀌어도 대시보드가 다른 타이머로 넘어가지 않는다
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    String label,
    Future<void> Function() command,
  ) async {
    ref.read(focusedTimerIdProvider.notifier).focus(activeTimer!.id);
    try {
      await command();
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, '$label 실패: ${error.toString()}');
      }
    }
  }

  /// 확인을 받고 지금 보이는 타이머를 완료한다
  Future<void> _stop(BuildContext context, WidgetRef ref) async {
    final activeTimer = ref
        .read(activeTimerProvider)
        .when(
          data: (timer) => timer,
          loading: () => null,
          error: (_, _) => null,
        );

    if (activeTimer == null || activeTimer.status == TimerStatus.completed) {
      ref.invalidate(myActiveTimersProvider);
      if (context.mounted) {
        showAppSnackBar(context, '진행 중인 작업이 없습니다.');
      }
      return;
    }

    final confirmed = await confirmStopTimer(context);
    if (!context.mounted || !confirmed) return;

    try {
      // 확인 시점에 캡처한 타이머 id로 정지 — 다이얼로그가 열린 사이
      // 활성 타이머가 바뀌어도 사용자가 확인한 타이머만 정지한다.
      await ref
          .read(timerControllerProvider.notifier)
          .stopTimer(timerId: activeTimer.id);
      if (context.mounted) {
        showAppSnackBar(
          context,
          '작업을 완료했습니다',
          actionLabel: '새 타이머 시작',
          onAction: () {
            if (!context.mounted) return;
            startTimerFromSheet(context, ref, initialDuration: pendingDuration);
          },
        );
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          '완료 실패: ${error.toString()}',
          kind: AppNoticeKind.error,
        );
      }
    }
  }
}
