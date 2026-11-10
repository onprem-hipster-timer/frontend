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

  /// 타이머 액션을 실행하고, 실패 시(예: WS 미연결) SnackBar로 피드백한다.
  /// 대시보드(`_pauseTimer` 등)와 동일하게
  /// 대시보드(`_pauseTimer` 등)·`TimerControlButtons`와 동일하게
  /// 히스토리 리스트의 액션에서도 예외가 사용자에게 전달되도록 한다.
  Future<void> _runTimerAction(
    BuildContext context,
    WidgetRef ref, {
    required Future<void> Function() action,
    required String errorLabel,
  }) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          '$errorLabel 실패: $error',
          kind: AppNoticeKind.error,
        );
      }
    }
  }

  /// 재개·연장한 타이머를 대시보드가 보이게 고른다
  void _focus(WidgetRef ref) =>
      ref.read(focusedTimerIdProvider.notifier).focus(timer.id);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 명령 응답 전 값이나 받은 응답을 목록을 다시 읽기 전에 먼저 보인다
    final timer = timerView(ref.watch(timerViewsProvider), this.timer);
    final style = timerStatusStyle(context, timer.status);
    final activeTimer = ref
        .watch(activeTimerProvider)
        .when(data: (t) => t, loading: () => null, error: (_, _) => null);
    final tickerAsync = ref.watch(timerTickerProvider);

    final taskName =
        timer.title ??
        timer.todo?.title ??
        timer.schedule?.title ??
        '알 수 없는 작업';

    final startTime = timer.startedAt != null
        ? formatTime(timer.startedAt!)
        : '--:--';
    final endTime = timer.endedAt != null
        ? formatTime(timer.endedAt!)
        : '--:--';

    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;

    final bool useLiveTicker =
        timer.status == TimerStatus.running && timer.id == activeTimer?.id;
    final now = ref.watch(serverClockProvider).now();
    final timeUp = isTimeUp(timer, now);
    final shown = isActive
        ? displayRemaining(timer, now)
        : displayElapsed(timer, now);
    final Duration duration = useLiveTicker
        ? tickerAsync.when(
            data: (d) => d,
            loading: () => shown,
            error: (_, _) => shown,
          )
        : shown;

    final buttons = [
      if (isActive) ...[
        if (timeUp)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _runTimerAction(
              context,
              ref,
              action: () {
                _focus(ref);
                return ref
                    .read(timerControllerProvider.notifier)
                    .extendTimer(timerId: timer.id, by: timerExtendStep);
              },
              errorLabel: '연장',
            ),
            tooltip: '5분 연장',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          )
        else if (timer.status == TimerStatus.running)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => _runTimerAction(
              context,
              ref,
              action: () => ref
                  .read(timerControllerProvider.notifier)
                  .pauseTimer(timerId: timer.id),
              errorLabel: '일시정지',
            ),
            tooltip: '일시정지',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
            ),
          )
        else if (timer.status == TimerStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _runTimerAction(
              context,
              ref,
              action: () {
                _focus(ref);
                return ref
                    .read(timerControllerProvider.notifier)
                    .resumeTimer(timerId: timer.id);
              },
              errorLabel: '재개',
            ),
            tooltip: '재개',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        IconButton(
          icon: Icon(Icons.check, color: theme.colorScheme.error),
          onPressed: () async {
            final confirmed = await confirmStopTimer(context);
            if (!context.mounted || !confirmed) return;
            await _runTimerAction(
              context,
              ref,
              action: () => ref
                  .read(timerControllerProvider.notifier)
                  .stopTimer(timerId: timer.id),
              errorLabel: '완료',
            );
          },
          tooltip: '완료',
        ),
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
        subtitle: Row(
          children: [
            if (isActive) ...[
              Flexible(child: TimerStatusChip(style)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                '$startTime - $endTime',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        time: durationText,
        timeGap: isActive ? 4 : 0,
        buttons: buttons,
      ),
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
