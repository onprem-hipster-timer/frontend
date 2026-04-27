import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';

/// 일정에 연결된 타이머 목록을 표시하는 섹션.
///
/// 자체적으로 [scheduleTimersProvider]를 watch하므로
/// 부모 위젯과 독립적으로 로딩/에러 상태를 처리합니다.
class ScheduleTimerSection extends ConsumerWidget {
  final String scheduleId;

  const ScheduleTimerSection({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timersAsync = ref.watch(scheduleTimersProvider(scheduleId));
    final theme = Theme.of(context);

    return timersAsync.when(
      data: (timers) {
        if (timers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Text(
                  '타이머',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
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
                    borderRadius: BorderRadius.circular(10),
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
            ...timers.map((timer) => _TimerRow(timer: timer)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _TimerRow extends StatelessWidget {
  final TimerRead timer;

  const _TimerRow({required this.timer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = getTimerStatusColor(timer.status);
    final statusText = getTimerStatusText(timer.status);

    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: Row(
        children: [
          Icon(getTimerStatusIcon(timer.status), size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timer.title ?? '제목 없음',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatDuration(Duration(seconds: timer.elapsedTime)),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
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
    );
  }
}
