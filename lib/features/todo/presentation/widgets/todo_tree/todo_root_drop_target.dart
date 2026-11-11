import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

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
        final isValidTarget = candidateData.isNotEmpty;
        final theme = Theme.of(context);

        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isValidTarget
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isValidTarget ? 2 : 1,
              style: BorderStyle.solid,
            ),
            borderRadius: AppRadius.mdAll,
            color: isValidTarget
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: 16,
                  color: isValidTarget
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '루트로 이동',
                  style: TextStyle(
                    color: isValidTarget
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isValidTarget
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
