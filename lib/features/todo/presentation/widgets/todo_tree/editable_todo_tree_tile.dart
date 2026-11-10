// 할 일 그룹 화면의 트리 한 줄과 그 하위
//
// 길게 눌러 다른 할 일 위에 놓으면 그 하위로 옮긴다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_actions.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tag_indicators.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_child_count_badge.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_elapsed_badge.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_chip.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_start_button.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 끄는 동안 원래 자리의 투명도
const double kDraggingOpacity = 0.5;

/// 고칠 수 있는 할 일 트리 한 줄. 펼쳐 있으면 하위를 같은 모양으로 이어 그린다.
///
/// 누르면 선택하고 [onTap]을 부른다. 상태 메뉴·수정·삭제·타이머 시작을 두고,
/// 길게 눌러 다른 줄 위에 놓으면 그 하위로 옮긴다(자기 하위 위에는 놓을 수 없다).
class EditableTodoTreeTile extends ConsumerWidget {
  const EditableTodoTreeTile({
    super.key,
    required this.node,
    required this.tree,
    this.onTap,
    this.onToggleExpand,
    this.initiallyExpanded,
  });

  final TodoTreeNode node;

  /// 놓을 수 있는지 볼 때 쓰는 전체 트리
  final TodoTree tree;
  final void Function(TodoRead todo)? onTap;

  /// 주면 펼침을 이것으로 알리고, 없으면 [expandedTodoIdsProvider]를 바꾼다
  final void Function(String todoId)? onToggleExpand;

  /// 주면 [expandedTodoIdsProvider] 대신 이 값으로 펼친다
  final bool? initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = node.todo;
    final expanded =
        initiallyExpanded ??
        ref.watch(expandedTodoIdsProvider).contains(todo.id);
    final selected = ref.watch(selectedTodoIdProvider) == todo.id;

    final view = TodoTreeTileView(
      todo: todo,
      depth: node.depth,
      leading: node.hasChildren
          ? _ExpandButton(
              expanded: expanded,
              onPressed: () => onToggleExpand != null
                  ? onToggleExpand!(todo.id)
                  : ref.read(expandedTodoIdsProvider.notifier).toggle(todo.id),
            )
          : null,
      status: TodoStatusSelector(todo: todo),
      meta: [
        if (canLinkTimer(todo)) TodoTimerChip(todoId: todo.id),
        TodoElapsedBadge(node: node),
        if (todo.tags.isNotEmpty) TodoTagIndicators(tags: todo.tags),
        if (node.hasChildren) TodoChildCountBadge(count: node.children.length),
      ],
      trailing: _TileActions(node: node),
      selected: selected,
      onTap: () {
        ref.read(selectedTodoIdProvider.notifier).select(todo.id);
        onTap?.call(todo);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropOnto(
          node: node,
          tree: tree,
          child: _DragHandle(todo: todo, child: view),
        ),
        if (node.hasChildren && expanded)
          for (final child in node.children)
            EditableTodoTreeTile(
              node: child,
              tree: tree,
              onTap: onTap,
              onToggleExpand: onToggleExpand,
            ),
      ],
    );
  }
}

/// 다른 할 일을 이 줄 위에 놓으면 이 할 일의 하위로 옮긴다
class _DropOnto extends ConsumerWidget {
  const _DropOnto({
    required this.node,
    required this.tree,
    required this.child,
  });

  final TodoTreeNode node;
  final TodoTree tree;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<TodoRead>(
      onWillAcceptWithDetails: (details) =>
          details.data.id != node.todo.id &&
          canDropOn(tree, details.data.id, node.todo.id),
      onAcceptWithDetails: (details) => updateTodoMutation.run(
        ref,
        (tsx) => tsx
            .get(todoMutationsProvider.notifier)
            .changeParent(details.data.id, node.todo.id),
      ),
      builder: (context, candidateData, rejectedData) {
        final scheme = Theme.of(context).colorScheme;
        final border = candidateData.isNotEmpty
            ? scheme.primary
            : rejectedData.isNotEmpty
            ? scheme.error
            : null;
        return Container(
          decoration: BoxDecoration(
            border: border == null ? null : Border.all(color: border, width: 2),
            borderRadius: AppRadius.smAll,
          ),
          child: child,
        );
      },
    );
  }
}

/// 길게 눌러 끌 수 있게 한다. 끄는 동안 [draggingTodoIdProvider]에 이 할 일을 둔다
class _DragHandle extends ConsumerWidget {
  const _DragHandle({required this.todo, required this.child});

  final TodoRead todo;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragging = ref.read(draggingTodoIdProvider.notifier);
    final theme = Theme.of(context);
    return LongPressDraggable<TodoRead>(
      data: todo,
      delay: const Duration(milliseconds: 200),
      hapticFeedbackOnStart: true,
      onDragStarted: () => dragging.setDragging(todo.id),
      onDragEnd: (_) => dragging.clear(),
      onDraggableCanceled: (_, _) => dragging.clear(),
      feedback: Material(
        elevation: 4,
        borderRadius: AppRadius.mdAll,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.8,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppRadius.mdAll,
          ),
          child: Text(
            todo.title,
            style: theme.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: kDraggingOpacity, child: child),
      child: child,
    );
  }
}

/// 하위를 펼치고 접는 버튼
class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedRotation(
        turns: expanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.chevron_right, size: 24),
      ),
    );
  }
}

/// 타이머 시작·수정·삭제 버튼
class _TileActions extends ConsumerWidget {
  const _TileActions({required this.node});

  final TodoTreeNode node;

  static final _compact = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    minimumSize: const Size(0, 32),
    textStyle: const TextStyle(fontSize: 12),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = node.todo;
    final error = Theme.of(context).colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canLinkTimer(todo)) TodoTimerStartButton(todo: todo),
        OutlinedButton.icon(
          onPressed: () => TodoActions.showEditTodoDialog(context, todo),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('수정'),
          style: _compact,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () =>
              TodoActions.showDeleteTodoDialog(context, ref, todo, node),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('삭제'),
          style: _compact.copyWith(
            foregroundColor: WidgetStatePropertyAll(error),
            side: WidgetStatePropertyAll(BorderSide(color: error)),
          ),
        ),
      ],
    );
  }
}
