import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/shared/api/rest/models/todo_read.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';

/// 할 일 관련 공통 액션 유틸리티
class TodoActions {
  TodoActions._();

  /// 할 일 수정 폼 시트 표시
  static void showEditTodoDialog(BuildContext context, TodoRead todo) {
    showTodoFormSheet(context, todo: todo);
  }

  /// 할 일 삭제 확인 다이얼로그 표시
  static Future<void> showDeleteTodoDialog(
    BuildContext context,
    WidgetRef ref,
    TodoRead todo,
    TodoTreeNode node,
  ) async {
    final hasChildren = node.children.isNotEmpty;
    final childWarning = hasChildren
        ? '\n하위 할 일 ${node.children.length}개도 함께 삭제됩니다.'
        : '';

    final confirmed = await showConfirmDialog(
      context,
      title: '할 일 삭제',
      content:
          '${todo.title}을(를) 삭제하시겠습니까?$childWarning\n'
          '이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        final success = await ref
            .read(todoMutationsProvider.notifier)
            .delete(todo.id);

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${todo.title}이(가) 삭제되었습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('할 일 삭제에 실패했습니다: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
