import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/core/utils/color_utils.dart';

/// Todo 대시보드 페이지
///
/// 그룹들을 카드 형태로 표시하는 메인 페이지입니다.
/// 개별 Todo 항목은 표시하지 않고, 그룹 선택만 담당합니다.
class TodoDashboardPage extends ConsumerWidget {
  const TodoDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagGroupsAsync = ref.watch(tagGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일 관리'),
        elevation: 0,
        centerTitle: true,
      ),
      body: tagGroupsAsync.when(
        data: (tagGroups) {
          if (tagGroups.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return _buildGroupGrid(context, theme, tagGroups);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(
          context,
          theme,
          error,
          onRetry: () => ref.invalidate(tagGroupsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context),
        icon: const Icon(Icons.create_new_folder),
        label: const Text('새 그룹 만들기'),
        tooltip: '새 그룹 만들기',
      ),
    );
  }

  /// 그룹 그리드 뷰
  Widget _buildGroupGrid(
    BuildContext context,
    ThemeData theme,
    List<TagGroupRead> todoGroups,
  ) {
    return CustomScrollView(
      slivers: [
        // 전체 통계 헤더
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _TodoStatsHeader(),
          ),
        ),

        // 그룹 그리드
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final group = todoGroups[index];
              return TodoGroupCard(
                group: group,
                onTap: () => context.go('${AppRoute.todo.path}/${group.id}'),
              );
            }, childCount: todoGroups.length),
          ),
        ),

        // 하단 여백 (FAB 가리지 않도록)
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              '그룹이 없습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '첫 번째 그룹을 만들어\n체계적으로 할 일을 관리해보세요!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('첫 그룹 만들기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    Object error, {
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '그룹을 불러오지 못했습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 새 그룹 생성 다이얼로그
  void _showCreateGroupDialog(BuildContext context) {
    showTagGroupFormSheet(context);
  }
}

/// Todo 그룹 카드 위젯
class TodoGroupCard extends ConsumerWidget {
  final TagGroupRead group;
  final VoidCallback onTap;

  const TodoGroupCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupColor = HexColor.fromHex(group.color);
    final statsAsync = ref.watch(todoStatsProvider(group.id));

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: groupColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 (아이콘 + 화살표)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: groupColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: groupColor,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 그룹 이름
                Text(
                  group.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // 설명 (있는 경우)
                if (group.description != null &&
                    group.description!.isNotEmpty) ...[
                  Text(
                    group.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                ],

                // 통계 정보
                statsAsync.when(
                  loading: () => const SizedBox(
                    height: 16,
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (stats) => _GroupStatsBadge(
                    stats: stats,
                    groupColor: groupColor,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 그룹 카드 하단 통계 배지
class _GroupStatsBadge extends StatelessWidget {
  final TodoStats stats;
  final Color groupColor;
  final ThemeData theme;

  const _GroupStatsBadge({
    required this.stats,
    required this.groupColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.checklist_rounded,
          size: 13,
          color: groupColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          '${stats.totalCount}개',
          style: theme.textTheme.labelSmall?.copyWith(
            color: groupColor.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 전체 통계 헤더 위젯
class _TodoStatsHeader extends ConsumerWidget {
  const _TodoStatsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(todoStatsProvider(null));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statsAsync.when(
          loading: () => _buildLoadingState(theme),
          error: (error, _) => _buildErrorState(theme, ref),
          data: (stats) => _buildStatsContent(context, theme, stats),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.dashboard_rounded, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '통계 로딩 중...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const LinearProgressIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, WidgetRef ref) {
    return Row(
      children: [
        Icon(Icons.dashboard_rounded, color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '그룹을 선택해서 할 일들을 관리하세요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          onPressed: () => ref.invalidate(todoStatsProvider(null)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }

  Widget _buildStatsContent(
    BuildContext context,
    ThemeData theme,
    TodoStats stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.dashboard_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              '전체 현황',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '총 ${stats.totalCount}개',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (stats.byTag.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: stats.byTag.take(5).map((tagStat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${tagStat.tagName} ${tagStat.count}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
