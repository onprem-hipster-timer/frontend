import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree_tile.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/core/utils/color_utils.dart';

/// Todo 그룹 상세 페이지
///
/// 특정 그룹에 속한 할 일들을 계층형 구조로 표시합니다.
/// 해당 그룹의 할 일만 서버에서 필터링하여 가져옵니다.
class TodoGroupDetailPage extends ConsumerWidget {
  final String groupId;

  const TodoGroupDetailPage({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 특정 그룹의 할 일들만 가져오기
    final todoTreeAsync = ref.watch(todoTreeProvider(groupId));
    final mutationState = ref.watch(todoMutationsProvider);

    // 그룹 정보 가져오기
    final groupAsync = ref.watch(tagGroupsProvider);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // AppBar with group info
              _buildAppBar(context, theme, groupAsync),

              // Todo list content
              todoTreeAsync.when(
                data: (tree) => _buildTodoList(context, ref, tree),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(context, theme, error),
                ),
              ),
            ],
          ),

          // 로딩 오버레이 (뮤테이션 중)
          if (mutationState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 77),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTodoDialog(context),
        tooltip: '이 그룹에 할 일 추가',
        child: const Icon(Icons.add_task),
      ),
    );
  }

  /// 그룹 정보가 포함된 AppBar
  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    AsyncValue<List<TagGroupRead>> groupAsync,
  ) {
    return groupAsync.when(
      data: (groups) {
        final group = groups.where((g) => g.id == groupId).firstOrNull;
        final groupColor = group != null
            ? HexColor.fromHex(group.color)
            : theme.colorScheme.primary;

        return SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: groupColor.withValues(alpha: 0.1),
          foregroundColor: groupColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoute.todo.path),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: '그룹 설정',
              onPressed: () => _showGroupSettings(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              group?.name ?? '할 일 그룹',
              style: TextStyle(
                color: groupColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    groupColor.withValues(alpha: 0.15),
                    groupColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: group?.description != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          group!.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: groupColor.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
      loading: () => SliverAppBar(
        title: const Text('로딩 중...'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoute.todo.path),
        ),
      ),
      error: (error, stack) => SliverAppBar(
        title: const Text('오류 발생'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoute.todo.path),
        ),
        backgroundColor: theme.colorScheme.errorContainer,
      ),
    );
  }

  /// Todo 목록 슬리버
  Widget _buildTodoList(
    BuildContext context,
    WidgetRef ref,
    dynamic tree,
  ) {
    if (tree.roots.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(context, Theme.of(context)),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // 상단 여백 및 안내
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '이 그룹의 할 일들입니다. 드래그로 순서를 바꿀 수 있습니다.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // 루트 드롭 타겟 (index == 1)
          if (index == 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TodoRootDropTarget(),
            );
          }

          // Todo 아이템들 (index >= 2)
          final treeIndex = index - 2;
          if (treeIndex >= tree.roots.length) {
            // 하단 여백 (FAB 가리지 않도록)
            return const SizedBox(height: 80);
          }

          final node = tree.roots[treeIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TodoTreeTile(
              node: node,
              tree: tree,
              onTap: (todo) => _showTodoDetail(context, todo),
            ),
          );
        },
        childCount: tree.roots.length + 3, // 안내 카드 + 드롭 타겟 + 아이템들 + 하단 여백
      ),
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
              Icons.task_alt_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              '이 그룹에는 할 일이 없습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '첫 번째 할 일을 추가해서\n체계적으로 작업을 관리해보세요!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateTodoDialog(context),
              icon: const Icon(Icons.add_task),
              label: const Text('첫 할 일 추가하기'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState(BuildContext context, ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '할 일을 불러오지 못했습니다',
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoute.todo.path),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('대시보드로'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    // 새로고침 로직
                    // ref.invalidate(todoTreeProvider(groupId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 할 일 상세 보기/수정
  void _showTodoDetail(BuildContext context, TodoRead todo) {
    showTodoFormSheet(
      context,
      todo: todo, // 수정 모드로 전달
    );
  }

  /// 할 일 생성 다이얼로그
  void _showCreateTodoDialog(BuildContext context) {
    showTodoFormSheet(
      context,
      defaultTagGroupId: groupId, // 현재 그룹 ID 전달
    );
  }

  /// 그룹 설정 다이얼로그
  void _showGroupSettings(BuildContext context) {
    // TODO: 그룹 설정 (수정/삭제) 구현
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('그룹 수정'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('그룹 수정 기능이 곧 구현됩니다!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('그룹 삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 삭제 확인 다이얼로그
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('그룹 삭제 기능이 곧 구현됩니다!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
