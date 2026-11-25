import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_status_chip.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 타이머 목록 항목에서 버튼 말고 한 줄에 필요한 폭 (여백, 상태 아이콘, 제목, 남은 시간). 글자 배율만큼 늘린다
const _historyItemBaseWidth = 280.0;

/// 타이머 목록 항목의 버튼 하나의 폭 (탭 영역 48)
const _historyItemButtonWidth = 48.0;

/// 타이머 히스토리 항목
///
/// RUNNING/PAUSED일 때 남은 시간을, 끝난 타이머는 경과 시간을 [duration]으로 받아 표시하고, 일시정지·재개·완료 버튼을 제공합니다.
/// 집중 시간이 끝난 타이머([timeUp])는 일시정지·재개 대신 연장 버튼을 둡니다.
/// 내 타이머는 맨 뒤에 공유 범위 버튼을 둡니다.
/// 버튼까지 한 줄에 두면 제목 자리가 모자란 폭이면 시간과 버튼을 제목 아래 줄로 내립니다.
class TimerHistoryItemView extends StatelessWidget {
  const TimerHistoryItemView({
    super.key,
    required this.timer,
    required this.duration,
    required this.timeUp,
    required this.onExtend,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final TimerRead timer;
  final Duration duration;
  final bool timeUp;
  final VoidCallback onExtend;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = timerStatusStyle(context, timer.status);
    final taskName =
        timer.title ??
        timer.todo?.title ??
        timer.schedule?.title ??
        '제목 없는 ${Terms.timer}';

    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;

    final buttons = [
      if (isActive) ...[
        _ActionButton(
          action: timeUp
              ? _Action.extend
              : timer.status == TimerStatus.running
              ? _Action.pause
              : _Action.resume,
          onPressed: timeUp
              ? onExtend
              : timer.status == TimerStatus.running
              ? onPause
              : onResume,
        ),
        _ActionButton(action: _Action.stop, onPressed: onStop),
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

/// 목록 항목의 타이머 조작 버튼 하나
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onPressed});

  final _Action action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, tooltip, color) = switch (action) {
      _Action.extend => (Icons.add, '5분 연장', colorScheme.primary),
      _Action.pause => (Icons.pause, '일시정지', colorScheme.secondary),
      _Action.resume => (Icons.play_arrow, '재개', colorScheme.primary),
      _Action.stop => (Icons.check, Terms.complete, colorScheme.error),
    };
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      style: IconButton.styleFrom(foregroundColor: color),
      onPressed: onPressed,
    );
  }
}

/// 타이머 목록 항목의 배치. 폭이 넉넉하면 [time]과 [buttons]를 제목 줄 오른쪽에 두고,
/// 모자라면 제목 아래 줄로 내린다(시간은 왼쪽, 버튼 묶음은 오른쪽, 그래도 모자라면 버튼 묶음을 다음 줄로)
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
