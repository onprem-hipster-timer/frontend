import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_form_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_root_drop_target.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일 그룹 상세 페이지
///
/// 할 일 그룹에 속한 할 일들을 계층형 구조로 표시합니다.
/// 해당 그룹의 할 일만 서버에서 필터링하여 가져옵니다.
class TodoGroupDetailPage extends ConsumerWidget {
  final String groupId;

  const TodoGroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 특정 그룹의 할 일들만 가져오기
    final todoTreeAsync = ref.watch(todoTreeProvider(groupId));
    final isTodoMutating =
        ref.watch(createTodoMutation).isPending ||
        ref.watch(updateTodoMutation).isPending ||
        ref.watch(deleteTodoMutation).isPending;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // AppBar with group info
              _GroupAppBar(groupId: groupId),

              // Todo list content
              todoTreeAsync.when(
                data: (tree) => _TodoList(groupId: groupId, tree: tree),
                loading: () => const SliverFillRemaining(child: AppLoading()),
                error: (error, stack) => SliverFillRemaining(
                  child: AppErrorState(
                    title: '${Terms.todo.withJosa('을', '를')} 불러오지 못했습니다',
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
        tooltip: '이 ${Terms.todoGroup}에 ${Terms.todo} 추가',
        child: const Icon(Icons.add_task),
      ),
    );
  }

  /// 할 일 생성 다이얼로그
  void _showCreateTodoDialog(BuildContext context) {
    showTodoFormSheet(
      context,
      defaultTodoGroupId: groupId, // 현재 그룹 ID 전달
    );
  }
}

/// 할 일 그룹 이름·색·설명을 보이는 앱바. 설정 메뉴에서 그룹을 고치거나 지운다(기본 그룹은 못 지운다).
class _GroupAppBar extends ConsumerWidget {
  const _GroupAppBar({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupAsync = ref.watch(todoGroupsProvider);
    return groupAsync.when(
      data: (groups) {
        final group = groups.where((g) => g.id == groupId).firstOrNull;
        final groupColor = group != null
            ? HexColor.fromHex(group.color)
            : theme.colorScheme.primary;

        final description = group?.description;
        return SliverMainAxisGroup(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: groupColor.withValues(alpha: 0.12),
              foregroundColor: groupColor,
              leading: const _BackToDashboard(),
              title: Text(
                group?.name ?? Terms.todoGroup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: groupColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                if (group != null)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: '${Terms.todoGroup} 설정',
                    onPressed: () => _showGroupSettings(context, ref, group),
                  ),
              ],
            ),
            if (description != null && description.isNotEmpty)
              SliverToBoxAdapter(
                child: ColoredBox(
                  color: groupColor.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => SliverAppBar(
        title: const Text('로딩 중...'),
        leading: const _BackToDashboard(),
      ),
      error: (error, stack) => SliverAppBar(
        title: const Text('오류 발생'),
        leading: const _BackToDashboard(),
        backgroundColor: theme.colorScheme.errorContainer,
      ),
    );
  }

  /// 그룹 설정 시트. 기본 그룹에는 삭제가 없다
  void _showGroupSettings(
    BuildContext context,
    WidgetRef ref,
    TodoGroupRead group,
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
              title: const Text('${Terms.todoGroup} 수정'),
              onTap: () {
                Navigator.pop(sheetContext);
                showTodoGroupFormSheet(context, group: group);
              },
            ),
            if (!group.isDefault)
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '${Terms.todoGroup} 삭제',
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

  /// 그룹 삭제 확인. 그룹의 할 일은 서버가 기본 그룹으로 옮긴다
  Future<void> _showDeleteGroupDialog(
    BuildContext context,
    WidgetRef ref,
    TodoGroupRead group,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '${Terms.todoGroup} 삭제',
      content:
          '${group.name} ${Terms.todoGroup.withJosa('을', '를')} 삭제하시겠습니까?\n'
          '이 ${Terms.todoGroup}의 ${Terms.todo.withJosa('은', '는')} '
          '기본 ${Terms.todoGroup.withJosa('으로', '로')} 옮겨집니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await deleteTodoGroupMutation.run(
          ref,
          (tsx) => tsx.get(todoGroupsProvider.notifier).deleteGroup(group.id),
        );

        if (context.mounted) {
          showAppSnackBar(
            context,
            '${group.name} ${Terms.todoGroup.withJosa('이', '가')} 삭제되었습니다',
          );
          context.go(AppRoute.todo.path);
        }
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            '${Terms.todoGroup} 삭제에 실패했습니다: $error',
            kind: AppNoticeKind.error,
          );
        }
      }
    }
  }
}

/// 그룹의 할 일 트리. 비었으면 첫 할 일 추가를 권한다.
class _TodoList extends StatelessWidget {
  const _TodoList({required this.groupId, required this.tree});

  final String groupId;
  final TodoTree tree;

  @override
  Widget build(BuildContext context) {
    if (tree.roots.isEmpty) {
      return SliverFillRemaining(
        child: AppEmptyState(
          icon: Icons.task_alt_rounded,
          title: '이 ${Terms.todoGroup}에는 ${Terms.todo.withJosa('이', '가')} 없습니다',
          message: '첫 번째 ${Terms.todo.withJosa('을', '를')} 추가해서\n체계적으로 관리해보세요!',
          actionLabel: '첫 ${Terms.todo} 추가하기',
          actionIcon: Icons.add_task,
          onAction: () =>
              showTodoFormSheet(context, defaultTodoGroupId: groupId),
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
                message:
                    '이 ${Terms.todoGroup}의 ${Terms.todo}들입니다. 드래그로 순서를 바꿀 수 있습니다.',
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
            child: EditableTodoTreeTile(
              node: node,
              tree: tree,
              onTap: (todo) => showTodoFormSheet(context, todo: todo),
            ),
          );
        },
        childCount: tree.roots.length + 3, // 안내 카드 + 드롭 타겟 + 아이템들 + 하단 여백
      ),
    );
  }
}

/// 할 일 대시보드로 돌아가는 뒤로 버튼
class _BackToDashboard extends StatelessWidget {
  const _BackToDashboard();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.go(AppRoute.todo.path),
    );
  }
}
