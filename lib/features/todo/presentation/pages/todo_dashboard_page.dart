import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
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
            return AppEmptyState(
              icon: Icons.folder_open_rounded,
              title: '그룹이 없습니다',
              message: '첫 번째 그룹을 만들어\n체계적으로 할 일을 관리해보세요!',
              actionLabel: '첫 그룹 만들기',
              onAction: () => _showCreateGroupDialog(context),
            );
          }

          return _buildGroupGrid(context, theme, tagGroups);
        },
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorState(
          title: '그룹을 불러오지 못했습니다',
          error: error,
          onRetry: () => ref.invalidate(tagGroupsRawProvider),
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
        // 헤더 정보
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.dashboard_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '그룹 관리',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '그룹을 선택해서 할 일들을 관리하세요.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                onTap: () => context.goNamed(
                  AppRoute.todoGroupDetail.name,
                  pathParameters: {'groupId': group.id},
                ),
              );
            }, childCount: todoGroups.length),
          ),
        ),

        // 하단 여백 (FAB 가리지 않도록)
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// 새 그룹 생성 다이얼로그
  void _showCreateGroupDialog(BuildContext context) {
    showTagGroupFormSheet(context);
  }
}

/// Todo 그룹 카드 위젯
class TodoGroupCard extends StatelessWidget {
  final TagGroupRead group;
  final VoidCallback onTap;

  const TodoGroupCard({super.key, required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupColor = HexColor.fromHex(group.color);

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
                // 헤더 (아이콘 + 상태)
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
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 그룹 이름
                Text(
                  group.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // 하단 정보 (TODO: 실제 할 일 개수 표시)
                const Row(
                  children: [
                    Spacer(),
                    // TODO: 실제 할 일 개수 표시
                    // Text(
                    //   'N개',
                    //   style: theme.textTheme.labelSmall?.copyWith(
                    //     color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    //   ),
                    // ),
                    // Text(
                    //   'N개',
                    //   style: theme.textTheme.labelSmall?.copyWith(
                    //     color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
