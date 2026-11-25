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
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tag_indicators.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_child_count_badge.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_elapsed_badge.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_chip.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_start_button.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 고칠 수 있는 할 일 트리 한 줄. 펼쳐 있으면 하위를 같은 모양으로 이어 그린다. 모양은 [EditableTodoTreeTileView]
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
    final dragging = ref.read(draggingTodoIdProvider.notifier);

    return EditableTodoTreeTileView(
      todo: todo,
      depth: node.depth,
      expanded: expanded,
      onToggleExpand: node.hasChildren
          ? () => onToggleExpand != null
                ? onToggleExpand!(todo.id)
                : ref.read(expandedTodoIdsProvider.notifier).toggle(todo.id)
          : null,
      status: TodoStatusSelector(todo: todo),
      meta: [
        if (canLinkTimer(todo)) TodoTimerChip(todoId: todo.id),
        TodoElapsedBadge(node: node),
        if (todo.tags.isNotEmpty) TodoTagIndicators(tags: todo.tags),
        if (node.hasChildren) TodoChildCountBadge(count: node.children.length),
      ],
      timerButton: canLinkTimer(todo) ? TodoTimerStartButton(todo: todo) : null,
      onEdit: () => TodoActions.showEditTodoDialog(context, todo),
      onDelete: () =>
          TodoActions.showDeleteTodoDialog(context, ref, todo, node),
      selected: selected,
      onTap: () {
        ref.read(selectedTodoIdProvider.notifier).select(todo.id);
        onTap?.call(todo);
      },
      canAccept: (dragged) =>
          dragged.id != todo.id && canDropOn(tree, dragged.id, todo.id),
      onAccept: (dragged) => updateTodoMutation.run(
        ref,
        (tsx) => tsx
            .get(todoMutationsProvider.notifier)
            .changeParent(dragged.id, todo.id),
      ),
      onDragStarted: () => dragging.setDragging(todo.id),
      onDragEnd: dragging.clear,
      children: [
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
