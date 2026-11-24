import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 일정에 연결된 타이머 목록을 표시하는 섹션.
///
/// 불러오는 중이거나 타이머가 없으면 아무것도 두지 않고, 못 불러오면 그렇다고 쓴다.
/// 타이머마다 [now] 기준 경과 시간을 보인다.
class ScheduleTimerSectionView extends StatelessWidget {
  final AsyncValue<List<TimerRead>> timers;

  /// 경과 시간을 셀 시각 (서버 기준)
  final DateTime now;

  const ScheduleTimerSectionView({
    super.key,
    required this.timers,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final timersAsync = timers;
    final theme = Theme.of(context);

    return timersAsync.when(
      data: (timers) {
        if (timers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  Terms.timer,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Text(
                    '${timers.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...timers.map((timer) => _TimerRow(timer: timer, now: now)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Text(
          '${Terms.timer.withJosa('을', '를')} 불러올 수 없습니다',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TimerRow extends StatelessWidget {
  final TimerRead timer;
  final DateTime now;

  const _TimerRow({required this.timer, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = getTimerStatusColor(context, timer.status);
    final statusText = getTimerStatusText(timer.status);

    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      // 좁으면 시간과 상태를 제목 다음 줄로 꺾는다
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(getTimerStatusIcon(timer.status), size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  timer.title ?? '제목 없음',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatDuration(displayElapsed(timer, now)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
