import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/mypage/presentation/providers/my_page_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/tag_stats_section_view.dart';

/// 마이페이지 태그 사용 통계 섹션
class TagStatsSection extends ConsumerWidget {
  const TagStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TagStatsSectionView(
      tagStats: ref.watch(tagUsageStatisticsProvider),
      onRetry: () => ref.invalidate(tagUsageStatisticsProvider),
    );
  }
}
