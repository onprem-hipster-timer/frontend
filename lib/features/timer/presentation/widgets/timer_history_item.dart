import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_history_item_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/features/timer/presentation/utils/timer_actions.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 타이머 히스토리 항목. 모양은 [TimerHistoryItemView]
///
/// RUNNING/PAUSED일 때 실시간 남은 시간을, 끝난 타이머는 경과 시간을 표시합니다.
/// 재개·연장하면 그 타이머를 대시보드가 보이게 고릅니다.
class TimerHistoryItem extends ConsumerWidget {
  final TimerRead timer;

  const TimerHistoryItem({super.key, required this.timer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 명령 응답 전 값이나 받은 응답을 목록을 다시 읽기 전에 먼저 보인다
    final timer = timerView(ref.watch(timerViewsProvider), this.timer);
    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;

    final now = ref.watch(serverClockProvider).now();
    final timeUp = isTimeUp(timer, now);
    final duration = _shownDuration(ref, timer, now, isActive: isActive);

    return TimerHistoryItemView(
      timer: timer,
      duration: duration,
      timeUp: timeUp,
      onExtend: () => _run(context, ref, timer, _Action.extend),
      onPause: () => _run(context, ref, timer, _Action.pause),
      onResume: () => _run(context, ref, timer, _Action.resume),
      onStop: () => _run(context, ref, timer, _Action.stop),
    );
  }
}

/// 보일 시간: 활성이면 남은 시간, 끝났으면 경과 시간. 대시보드가 보는 RUNNING 타이머는 초마다 갱신되는 값을 쓴다
Duration _shownDuration(
  WidgetRef ref,
  TimerRead timer,
  DateTime now, {
  required bool isActive,
}) {
  final shown = isActive
      ? displayRemaining(timer, now)
      : displayElapsed(timer, now);
  final activeId = ref
      .watch(activeTimerProvider)
      .whenOrNull(data: (t) => t)
      ?.id;
  if (timer.status != TimerStatus.running || timer.id != activeId) {
    return shown;
  }
  return ref.watch(timerTickerProvider).whenOrNull(data: (d) => d) ?? shown;
}

enum _Action { extend, pause, resume, stop }

/// [timer]에 조작 하나를 보낸다. 실패하면(예: WS 미연결) 알림으로 알린다.
/// 재개·연장한 타이머는 대시보드가 보이게 고르고, 완료는 먼저 확인을 받는다.
Future<void> _run(
  BuildContext context,
  WidgetRef ref,
  TimerRead timer,
  _Action action,
) async {
  final label = switch (action) {
    _Action.extend => '연장',
    _Action.pause => '일시정지',
    _Action.resume => '재개',
    _Action.stop => Terms.complete,
  };
  if (action == _Action.stop) {
    final confirmed = await confirmStopTimer(context);
    if (!context.mounted || !confirmed) return;
  }
  final controller = ref.read(timerControllerProvider.notifier);
  if (action == _Action.extend || action == _Action.resume) {
    ref.read(focusedTimerIdProvider.notifier).focus(timer.id);
  }
  try {
    await switch (action) {
      _Action.extend => controller.extendTimer(
        timerId: timer.id,
        by: timerExtendStep,
      ),
      _Action.pause => controller.pauseTimer(timerId: timer.id),
      _Action.resume => controller.resumeTimer(timerId: timer.id),
      _Action.stop => controller.stopTimer(timerId: timer.id),
    };
  } catch (error) {
    if (context.mounted) {
      showAppSnackBar(context, '$label 실패: $error', kind: AppNoticeKind.error);
    }
  }
}
