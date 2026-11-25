import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_form_sheet_view.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 할 일 그룹 생성/수정 폼 시트. 칸은 [TodoGroupFormSheetView]
///
/// 새로 만들면 '목록 보기'(만든 그룹 화면으로 이동)가 있는 알림을 띄운다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_group_form_sheet_test.dart
class TodoGroupFormSheet extends ConsumerStatefulWidget {
  /// 수정할 할 일 그룹 (null이면 생성)
  final TodoGroupRead? group;

  const TodoGroupFormSheet({super.key, this.group});

  @override
  ConsumerState<TodoGroupFormSheet> createState() => _TodoGroupFormSheetState();
}

class _TodoGroupFormSheetState extends ConsumerState<TodoGroupFormSheet> {
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.group != null;
    final isLoading = isEditMode
        ? ref.watch(updateTodoGroupMutation).isPending
        : ref.watch(createTodoGroupMutation).isPending;
    return TodoGroupFormSheetView(
      group: widget.group,
      busy: isLoading,
      onSubmit: _handleSubmit,
    );
  }

  Future<void> _handleSubmit(
    String name,
    String description,
    Color color,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final group = widget.group;
    VoidCallback? openCreated;
    try {
      if (group != null) {
        await updateTodoGroupMutation.run(
          ref,
          (tsx) => tsx
              .get(todoGroupsProvider.notifier)
              .updateGroup(
                group.id,
                TodoGroupUpdate(
                  name: name,
                  color: color.toHex(),
                  description: description.isEmpty ? null : description,
                ),
                options: description.isEmpty
                    ? explicitNulls(['description'])
                    : null,
              ),
        );
      } else {
        // 시트를 닫은 뒤에도 알림에서 이동할 수 있게 라우터를 잡아 둔다
        final router = GoRouter.of(context);
        final created = await createTodoGroupMutation.run(
          ref,
          (tsx) => tsx
              .get(todoGroupsProvider.notifier)
              .createGroup(
                TodoGroupCreate(
                  name: name,
                  color: color.toHex(),
                  description: description.isEmpty ? null : description,
                ),
              ),
        );
        openCreated = () => router.goNamed(
          AppRoute.todoGroupDetail.name,
          pathParameters: {'groupId': created.id},
        );
      }
      if (!mounted) return;
      navigator.pop();
      messenger.showAppSnackBar(
        group != null
            ? '${Terms.todoGroup.withJosa('이', '가')} 수정되었습니다'
            : '${Terms.todoGroup.withJosa('이', '가')} 생성되었습니다',
        kind: AppNoticeKind.success,
        actionLabel: openCreated == null ? null : '${Terms.list} 보기',
        onAction: openCreated,
      );
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        group != null
            ? '${Terms.todoGroup} 수정에 실패했습니다: $error'
            : '${Terms.todoGroup} 생성에 실패했습니다: $error',
        kind: AppNoticeKind.error,
      );
    }
  }
}

/// 할 일 그룹 폼 시트를 연다. [group]을 주면 수정, 아니면 생성
Future<void> showTodoGroupFormSheet(
  BuildContext context, {
  TodoGroupRead? group,
}) {
  return showAppSheet<void>(
    context,
    builder: (context) => TodoGroupFormSheet(group: group),
  );
}
