import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/core/network/explicit_null_interceptor.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/linked_schedule_policy_dialog.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_form_status_chips.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 서버에 보낼 상태. UNSCHEDULED/SCHEDULED는 서버가 마감일 유무로 정하는 값이라
/// 보내지 않는다(보내서 실제와 다르면 422). 사용자가 고르는 상태는 완료·취소뿐이다.
@visibleForTesting
TodoStatus? todoStatusForRequest(TodoStatus selected) =>
    isActiveTodoStatus(selected) ? null : selected;

/// 마감일 고르기. 고르지 않고 닫으면 null
Future<DateTime?> pickTodoDeadline(BuildContext context, DateTime? current) {
  return showAppDatePicker(context, initial: current ?? DateTime.now());
}

/// 할 일 폼에서 고른 값. [description]이 비었으면 설명이 없고, [todoGroupId]가 null이면 기본 그룹이다
typedef TodoFormValues = ({
  String title,
  String description,
  TodoStatus status,
  List<String> tagIds,
  DateTime? deadline,
  String? todoGroupId,
});

/// [todo]를 [values]로 고친다
///
/// 비운 설명과 지운 마감일은 null로 보낸다. 할 일 그룹은 바뀌었을 때만 보낸다(서버가 하위 할 일을 함께 옮긴다).
/// 예정된 할 일의 마감일을 지우면 연결된 일정 처리를 묻고, 질문을 닫으면 보내지 않고 false를 돌려준다.
Future<bool> updateTodoFromForm(
  BuildContext context,
  WidgetRef ref,
  TodoRead todo,
  TodoFormValues values,
) async {
  final removesDeadline = todo.deadline != null && values.deadline == null;
  LinkedSchedulePolicy? linkedSchedulePolicy;
  // SCHEDULED = 연결 일정이 있다는 서버 표시
  if (removesDeadline && todo.status == TodoStatus.scheduled) {
    linkedSchedulePolicy = await showLinkedSchedulePolicyDialog(
      context,
      todoTitle: todo.title,
    );
    if (linkedSchedulePolicy == null) return false;
  }
  final description = values.description;
  final nullFields = [
    if (description.isEmpty) 'description',
    if (removesDeadline) 'deadline',
  ];
  await updateTodoMutation.run(
    ref,
    (tsx) => tsx
        .get(todoMutationsProvider.notifier)
        .update(
          todo.id,
          TodoUpdate(
            title: values.title,
            description: description.isEmpty ? null : description,
            todoGroupId: values.todoGroupId == todo.todoGroupId
                ? null
                : values.todoGroupId,
            status: todoStatusForRequest(values.status),
            tagIds: values.tagIds,
            deadline: values.deadline,
            linkedSchedulePolicy: linkedSchedulePolicy,
          ),
          options: nullFields.isEmpty ? null : explicitNulls(nullFields),
        ),
  );
  return true;
}

/// [todo]를 [values]로 고친 뒤의 알림. 할 일 그룹을 옮겼고 [groups]에서 그 이름을 찾으면 옮긴 곳을 알린다
String todoUpdatedMessage(
  TodoRead todo,
  TodoFormValues values,
  List<TodoGroupRead>? groups,
) {
  final target = values.todoGroupId == todo.todoGroupId
      ? null
      : groups?.where((group) => group.id == values.todoGroupId).firstOrNull;
  if (target == null) return '${Terms.todo.withJosa('이', '가')} 수정되었습니다';
  return "'${target.name}' ${Terms.todoGroup.withJosa('으로', '로')} 옮겼습니다";
}

/// [values]로 할 일을 만든다(할 일 그룹이 없으면 서버가 기본 그룹에 넣는다). [parentId]를 주면 그 할 일의 하위로 만든다
Future<void> createTodoFromForm(
  WidgetRef ref,
  TodoFormValues values, {
  String? parentId,
}) {
  return createTodoMutation.run(
    ref,
    (tsx) => tsx
        .get(todoMutationsProvider.notifier)
        .create(
          TodoCreate(
            title: values.title,
            todoGroupId: values.todoGroupId,
            status: todoStatusForRequest(values.status),
            description: values.description.isEmpty ? null : values.description,
            tagIds: values.tagIds,
            deadline: values.deadline,
            parentId: parentId,
          ),
        ),
  );
}
