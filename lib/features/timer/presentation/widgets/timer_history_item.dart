import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/features/timer/presentation/utils/timer_actions.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_status_chip.dart';

/// 타이머 목록 항목에서 버튼 말고 한 줄에 필요한 폭 (여백, 상태 아이콘, 제목, 남은 시간). 글자 배율만큼 늘린다
const _historyItemBaseWidth = 280.0;

/// 타이머 목록 항목의 버튼 하나의 폭 (탭 영역 48)
const _historyItemButtonWidth = 48.0;

/// 타이머 히스토리 항목
///
/// RUNNING/PAUSED일 때 실시간 남은 시간을, 끝난 타이머는 경과 시간을 표시하고, 일시정지·재개·완료 버튼을 제공합니다.
/// 집중 시간이 끝난 타이머는 일시정지·재개 대신 연장 버튼을 둡니다. 재개·연장하면 그 타이머를 대시보드가 보이게 고릅니다.
/// 내 타이머는 맨 뒤에 공유 범위 버튼을 둡니다.
/// 버튼까지 한 줄에 두면 제목 자리가 모자란 폭이면 시간과 버튼을 제목 아래 줄로 내립니다.
class TimerHistoryItem extends ConsumerWidget {
  final TimerRead timer;

  const TimerHistoryItem({super.key, required this.timer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 명령 응답 전 값이나 받은 응답을 목록을 다시 읽기 전에 먼저 보인다
    final timer = timerView(ref.watch(timerViewsProvider), this.timer);
    final style = timerStatusStyle(context, timer.status);
    final taskName =
        timer.title ??
        timer.todo?.title ??
        timer.schedule?.title ??
        '알 수 없는 작업';

    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;

    final now = ref.watch(serverClockProvider).now();
    final timeUp = isTimeUp(timer, now);
    final duration = _shownDuration(ref, timer, now, isActive: isActive);

    final buttons = [
      if (isActive) ...[
        _ActionButton(
          timer: timer,
          action: timeUp
              ? _Action.extend
              : timer.status == TimerStatus.running
              ? _Action.pause
              : _Action.resume,
        ),
        _ActionButton(timer: timer, action: _Action.stop),
      ],
      if (!timer.isShared) TimerShareButton(timer: timer),
    ];
    final durationText = Text(
      formatDuration(duration),
      style: theme.textTheme.titleSmall?.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        color: isActive ? style.fg : theme.colorScheme.primary,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: _HistoryItemLayout(
        leading: CircleAvatar(
          backgroundColor: style.bg,
          child: Icon(style.icon, color: style.fg),
        ),
        title: Text(
          taskName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: _TimesLine(timer: timer, style: isActive ? style : null),
        time: durationText,
        timeGap: isActive ? 4 : 0,
        buttons: buttons,
      ),
    );
  }
}

/// 타이머 목록 항목의 배치. 폭이 넉넉하면 [time]과 [buttons]를 제목 줄 오른쪽에 두고,
/// 모자라면 제목 아래 줄로 내린다(시간은 왼쪽, 버튼 묶음은 오른쪽, 그래도 모자라면 버튼 묶음을 다음 줄로)
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

/// 상태 칩([style]이 있을 때)과 시작–끝 시각
class _TimesLine extends StatelessWidget {
  const _TimesLine({required this.timer, required this.style});

  final TimerRead timer;
  final TimerStatusStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    final start = timer.startedAt == null
        ? '--:--'
        : formatTime(timer.startedAt!);
    final end = timer.endedAt == null ? '--:--' : formatTime(timer.endedAt!);
    // 한 줄에 다 들어가지 않으면 시각을 상태 아래 줄로 내리고, 그래도 넘치면 시각도 줄을 바꾼다
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (style != null) TimerStatusChip(style),
        Text('$start - $end'),
      ],
    );
  }
}

enum _Action { extend, pause, resume, stop }

/// 목록 항목의 타이머 조작 버튼 하나. 실패하면(예: WS 미연결) 알림으로 알린다.
/// 재개·연장한 타이머는 대시보드가 보이게 고르고, 완료는 먼저 확인을 받는다.
class _ActionButton extends ConsumerWidget {
  const _ActionButton({required this.timer, required this.action});

  final TimerRead timer;
  final _Action action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, tooltip, color) = switch (action) {
      _Action.extend => (Icons.add, '5분 연장', colorScheme.primary),
      _Action.pause => (Icons.pause, '일시정지', colorScheme.secondary),
      _Action.resume => (Icons.play_arrow, '재개', colorScheme.primary),
      _Action.stop => (Icons.check, '완료', colorScheme.error),
    };
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(foregroundColor: color),
      onPressed: () =>
          _run(context, ref, action == _Action.extend ? '연장' : tooltip),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, String label) async {
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
        showAppSnackBar(
          context,
          '$label 실패: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }
}

class _HistoryItemLayout extends StatelessWidget {
  const _HistoryItemLayout({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.timeGap,
    required this.buttons,
  });

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget time;
  final double timeGap;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    final baseWidth = MediaQuery.textScalerOf(
      context,
    ).scale(_historyItemBaseWidth);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            buttons.isNotEmpty &&
            constraints.maxWidth <
                baseWidth + _historyItemButtonWidth * buttons.length;
        final tile = ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: stacked
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    time,
                    SizedBox(width: timeGap),
                    ...buttons,
                  ],
                ),
        );
        if (!stacked) return tile;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            tile,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  time,
                  Row(mainAxisSize: MainAxisSize.min, children: buttons),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
