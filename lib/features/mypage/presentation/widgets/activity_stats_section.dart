import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 마이페이지 활동 통계 섹션
class ActivityStatsSection extends ConsumerWidget {
  const ActivityStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(todoStatisticsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활동 요약',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: statsAsync.when(
              data: (stats) => _StatsBody(stats: stats),
              loading: () => const _StatsSkeleton(),
              error: (error, stack) => AppErrorState(
                title: '통계 데이터를 불러올 수 없습니다',
                onRetry: () => ref.invalidate(todosProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 전체 진행률 막대와 상태별 수
class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final TodoStatistics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final heading = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final counts = [
      ('전체', stats.totalCount, colorScheme.primary),
      ('미지정', stats.unscheduledCount, colorScheme.secondary),
      ('예정', stats.scheduledCount, colorScheme.tertiary),
      ('완료', stats.doneCount, colorScheme.tertiaryContainer),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '전체 진행률 (${stats.doneCount}개 완료 / ${stats.totalCount}개 전체)',
          style: heading,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: LinearProgressIndicator(
            value: stats.completionRate,
            minHeight: 10,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text('${Terms.todo} 상태별 현황', style: heading),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (i, (label, count, color)) in counts.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _StatusCount(
                  label: label,
                  count: '$count',
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// 불러오는 동안 [_StatsBody] 자리를 채우는 회색 막대들
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Bar(width: 200, height: 20, radius: AppRadius.smAll),
        const SizedBox(height: 12),
        _Bar(width: double.infinity, height: 10, radius: AppRadius.mdAll),
        const SizedBox(height: 24),
        _Bar(width: 150, height: 20, radius: AppRadius.smAll),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _Bar(
                  width: double.infinity,
                  height: 60,
                  radius: AppRadius.lgAll,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.radius});

  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
      ),
    );
  }
}

/// 상태 하나의 수. 수와 이름을 한 번에 읽힌다
class _StatusCount extends StatelessWidget {
  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
