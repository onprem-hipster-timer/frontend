import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/activity_stats_section_view.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';

/// 마이페이지 활동 통계 섹션
class ActivityStatsSection extends ConsumerWidget {
  const ActivityStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActivityStatsSectionView(
      stats: ref.watch(todoStatisticsProvider),
      onRetry: () => ref.invalidate(todosProvider),
    );
  }
}
