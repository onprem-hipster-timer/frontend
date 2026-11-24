import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_root_drop_target_view.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 루트 드롭 타겟 (루트로 이동)
///
/// 트리 상단에 배치하여 할 일을 루트 레벨로 이동할 수 있게 합니다.
class TodoRootDropTarget extends ConsumerWidget {
  const TodoRootDropTarget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<TodoRead>(
      onWillAcceptWithDetails: (details) {
        // 이미 루트인 경우 드롭 불필요
        return details.data.parentId != null;
      },
      onAcceptWithDetails: (details) async {
        final draggedTodo = details.data;
        // 부모를 null로 설정하여 루트로 이동
        await updateTodoMutation.run(
          ref,
          (tsx) => tsx
              .get(todoMutationsProvider.notifier)
              .changeParent(draggedTodo.id, null),
        );
      },
      builder: (context, candidateData, rejectedData) {
        return TodoRootDropTargetView(highlighted: candidateData.isNotEmpty);
      },
    );
  }
}
