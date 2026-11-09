import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree_tile.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/core/utils/color_utils.dart';

/// Todo 그룹 상세 페이지
///
/// 특정 그룹에 속한 할 일들을 계층형 구조로 표시합니다.
/// 해당 그룹의 할 일만 서버에서 필터링하여 가져옵니다.
class TodoGroupDetailPage extends ConsumerWidget {
  final String groupId;

  const TodoGroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 특정 그룹의 할 일들만 가져오기
    final todoTreeAsync = ref.watch(todoTreeProvider(groupId));
    final isTodoMutating =
        ref.watch(createTodoMutation).isPending ||
        ref.watch(updateTodoMutation).isPending ||
        ref.watch(deleteTodoMutation).isPending;

    // 그룹 정보 가져오기
    final groupAsync = ref.watch(tagGroupsProvider);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // AppBar with group info
              _buildAppBar(context, ref, theme, groupAsync),

              // Todo list content
              todoTreeAsync.when(
                data: (tree) => _buildTodoList(context, ref, tree),
                loading: () => const SliverFillRemaining(child: AppLoading()),
                error: (error, stack) => SliverFillRemaining(
                  child: AppErrorState(
                    title: '할 일을 불러오지 못했습니다',
                    error: error,
                    secondaryLabel: '대시보드로',
                    onSecondary: () => context.go(AppRoute.todo.path),
                    onRetry: () => ref.invalidate(todosProvider(groupId)),
                  ),
                ),
              ),
            ],
          ),

          // 로딩 오버레이 (뮤테이션 중)
          if (isTodoMutating)
            Container(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.3),
              child: const AppLoading(),
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
    WidgetRef ref,
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
            if (group != null)
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: '그룹 설정',
                onPressed: () => _showGroupSettings(context, ref, group),
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              group?.name ?? '할 일 그룹',
              style: TextStyle(color: groupColor, fontWeight: FontWeight.w600),
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
  Widget _buildTodoList(BuildContext context, WidgetRef ref, dynamic tree) {
    if (tree.roots.isEmpty) {
      return SliverFillRemaining(
        child: AppEmptyState(
          icon: Icons.task_alt_rounded,
          title: '이 그룹에는 할 일이 없습니다',
          message: '첫 번째 할 일을 추가해서\n체계적으로 작업을 관리해보세요!',
          actionLabel: '첫 할 일 추가하기',
          actionIcon: Icons.add_task,
          onAction: () => _showCreateTodoDialog(context),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // 상단 여백 및 안내
            return Padding(
              padding: const EdgeInsets.all(16),
              child: const AppHintCard(
                message: '이 그룹의 할 일들입니다. 드래그로 순서를 바꿀 수 있습니다.',
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
  void _showGroupSettings(
    BuildContext context,
    WidgetRef ref,
    TagGroupRead group,
  ) {
    showAppSheet<void>(
      context,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('그룹 수정'),
              onTap: () {
                Navigator.pop(sheetContext);
                showTagGroupFormSheet(
                  context,
                  tagGroup: TagGroupReadWithTags(
                    id: group.id,
                    name: group.name,
                    color: group.color,
                    createdAt: group.createdAt,
                    updatedAt: group.updatedAt,
                    description: group.description,
                    goalRatios: group.goalRatios,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '그룹 삭제',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteGroupDialog(context, ref, group);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 그룹 삭제 확인 다이얼로그
  Future<void> _showDeleteGroupDialog(
    BuildContext context,
    WidgetRef ref,
    TagGroupRead group,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '그룹 삭제',
      content:
          '${group.name} 그룹을 삭제하시겠습니까?\n'
          '이 작업은 되돌릴 수 없습니다.\n'
          '그룹에 포함된 모든 태그도 함께 삭제됩니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await deleteTagGroupMutation.run(
          ref,
          (tsx) => tsx.get(tagGroupsRawProvider.notifier).deleteGroup(group.id),
        );

        if (context.mounted) {
          showAppSnackBar(context, '${group.name} 그룹이 삭제되었습니다');
          context.go(AppRoute.todo.path);
        }
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            '그룹 삭제에 실패했습니다: $error',
            kind: AppNoticeKind.error,
          );
        }
      }
    }
  }
}
