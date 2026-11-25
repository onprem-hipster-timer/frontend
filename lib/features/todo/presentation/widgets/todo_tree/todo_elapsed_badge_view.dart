import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 할 일의 누적 집중 시간 배지. 끝난 타이머 시간 [finishedSeconds]에 도는 타이머의 경과 시간
/// [activeSeconds]를 더해 보인다. 도는 타이머가 있으면 강조 색이고, 시간이 없으면 표시하지 않는다.
class TodoElapsedBadgeView extends StatelessWidget {
  const TodoElapsedBadgeView({
    super.key,
    required this.finishedSeconds,
    this.activeSeconds,
  });

  final int finishedSeconds;

  /// 도는 타이머의 경과 시간 합. 도는 타이머가 없으면 null
  final int? activeSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finished = finishedSeconds;
    final active = activeSeconds;
    if (finished == 0 && active == null) return const SizedBox.shrink();

    final isActive = active != null;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.mdAll,
        ),
        child: Text(
          formatDuration(Duration(seconds: finished + (active ?? 0))),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
