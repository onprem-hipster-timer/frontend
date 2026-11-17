import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/utils/linked_timer_policy_dialog.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/linked_schedule_policy_dialog.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/domain/terms.dart';

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
        ? '\n하위 ${Terms.todo} ${node.children.length}개도 함께 삭제됩니다.'
        : '';

    final confirmed = await showAppConfirmDialog(
      context,
      title: '${Terms.todo} 삭제',
      content:
          '${todo.title}을(를) 삭제하시겠습니까?$childWarning\n'
          '되돌릴 수 없습니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
      // 연결된 캘린더 일정(SCHEDULED)이 있으면 처리 정책을 받아야 서버가 삭제한다
      LinkedSchedulePolicy? policy;
      if (todo.status == TodoStatus.scheduled) {
        policy = await showLinkedSchedulePolicyDialog(
          context,
          todoTitle: todo.title,
        );
        if (policy == null || !context.mounted) return;
      }
      try {
        final deleted = await deleteAskingLinkedTimerPolicy(
          context,
          itemTitle: todo.title,
          delete: (timerPolicy) => deleteTodoMutation.run(
            ref,
            (tsx) => tsx
                .get(todoMutationsProvider.notifier)
                .delete(
                  todo.id,
                  linkedSchedulePolicy: policy,
                  linkedTimerPolicy: timerPolicy,
                ),
          ),
        );

        if (deleted && context.mounted) {
          showAppSnackBar(context, '${todo.title}이(가) 삭제되었습니다');
        }
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            '${Terms.todo} 삭제에 실패했습니다: $error',
            kind: AppNoticeKind.error,
          );
        }
      }
    }
  }
}
