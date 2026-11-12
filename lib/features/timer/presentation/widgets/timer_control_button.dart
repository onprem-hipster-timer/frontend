import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 타이머 제어 버튼
///
/// 일시정지·재개는 누르는 즉시 [activeTimer]에 반영되므로 버튼을 그대로 둔다.
/// 새 타이머 시작만 응답을 기다리고([starting]), 그동안 시작 버튼 안에 진행 표시를 둔다.
/// 집중 시간이 끝나면([timeUp]) 일시정지·재개 대신 연장([onExtend]) 버튼을 둔다.
/// 활성 타이머 없이 휴식을 골랐으면([breakSelected]) 시작 버튼이 휴식을 바로 시작하고([onStartBreak]),
/// 시간이 남은 일시정지 타이머와 시간이 끝난 타이머에는 휴식 버튼을 더 둔다. 휴식을 시작할 수 없으면 [onStartBreak]이 null이고 휴식 버튼이 없다.
/// 버튼 사이 간격. 오탭을 막으려 넉넉히 두되, 좁은 칸에서는 줄어든다
const _gap = Flexible(child: SizedBox(width: 40));

class TimerControlButton extends StatelessWidget {
  final TimerRead? activeTimer;
  final bool starting;
  final bool timeUp;
  final bool breakSelected;
  final VoidCallback onStart;
  final VoidCallback? onStartBreak;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onExtend;

  const TimerControlButton({
    super.key,
    required this.activeTimer,
    required this.starting,
    required this.timeUp,
    required this.breakSelected,
    required this.onStart,
    required this.onStartBreak,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeTimer == null && breakSelected) {
      return FloatingActionButton(
        onPressed: onStartBreak,
        tooltip: '${Terms.rest} 시작',
        backgroundColor: theme.colorScheme.tertiary,
        child: Icon(
          Icons.coffee,
          size: 32,
          color: theme.colorScheme.onTertiary,
        ),
      );
    }
    if (activeTimer == null) {
      return FloatingActionButton(
        onPressed: starting ? null : onStart,
        backgroundColor: theme.colorScheme.primary,
        child: starting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Icon(
                Icons.play_arrow,
                size: 32,
                color: theme.colorScheme.onPrimary,
              ),
      );
    }

    // 위계: 자주 쓰는 일시정지·재개·연장을 큰 주 버튼(primary), 비가역 완료는
    // 작은 보조 버튼(error)으로 + 간격을 넓혀 오탭을 방지한다.
    final running = activeTimer!.status == TimerStatus.running;
    final (mainIcon, onMain, mainTooltip) = timeUp
        ? (Icons.add, onExtend, '5분 연장')
        : running
        ? (Icons.pause, onPause, null)
        : (Icons.play_arrow, onResume, null);
    final onBreak = timeUp || !running ? onStartBreak : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SmallButton(
          onPressed: onStop,
          tooltip: Terms.complete,
          icon: Icons.check,
          background: theme.colorScheme.error,
          foreground: theme.colorScheme.onError,
        ),
        _gap,
        FloatingActionButton(
          onPressed: onMain,
          tooltip: mainTooltip,
          backgroundColor: theme.colorScheme.primary,
          child: Icon(mainIcon, color: theme.colorScheme.onPrimary),
        ),
        if (onBreak != null) ...[
          _gap,
          _SmallButton(
            onPressed: onBreak,
            tooltip: Terms.rest,
            icon: Icons.coffee,
            background: theme.colorScheme.tertiary,
            foreground: theme.colorScheme.onTertiary,
          ),
        ],
      ],
    );
  }
}

/// 주 버튼 양옆의 작은 버튼(완료·휴식)
class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: background,
      child: Icon(icon, color: foreground),
    );
  }
}
