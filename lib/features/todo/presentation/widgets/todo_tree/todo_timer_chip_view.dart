import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 남은 시간을 mm:ss로, 한 시간 이상이면 h:mm:ss로 쓴다
String _formatRemaining(Duration remaining) {
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = remaining.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// 할 일에 연결된 타이머의 남은 시간 칩. 누르면 [onPressed]를, 없으면 타이머 화면으로 간다
///
/// 남은 시간이 0이면 에러 색이다.
class TodoTimerChipView extends StatelessWidget {
  const TodoTimerChipView({
    super.key,
    required this.remainingSeconds,
    this.onPressed,
  });

  final int remainingSeconds;

  /// 누르면 부른다. 체험하기 흐름이 타이머 화면 대신 제 단계로 가려고 받는다
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final remaining = remainingSeconds;
    final theme = Theme.of(context);
    final color = remaining == 0
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: ActionChip(
        avatar: Icon(Icons.timer_outlined, color: color),
        label: Text(_formatRemaining(Duration(seconds: remaining))),
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
        tooltip: '${Terms.timer.withJosa('으로', '로')} 이동',
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: onPressed ?? () => context.go(AppRoute.timer.path),
      ),
    );
  }
}
