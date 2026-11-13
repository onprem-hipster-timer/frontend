import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 할 일 폼의 할 일 그룹 칸. 누르면 그룹을 고르는 대화상자를 연다.
///
/// [selectedId]가 null이면 기본 그룹을 보인다(보내지 않으면 서버가 기본 그룹에 넣는다).
class TodoGroupField extends ConsumerWidget {
  const TodoGroupField({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.locked = false,
  });

  final String? selectedId;
  final ValueChanged<String> onChanged;

  /// 바꿀 수 없게 한다(하위 할 일은 상위 할 일의 그룹을 따른다)
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(todoGroupsProvider);
    final list = groups.value ?? const <TodoGroupRead>[];
    final selected =
        list.where((group) => group.id == selectedId).firstOrNull ??
        (selectedId == null ? defaultTodoGroupOf(list) : null);
    return AppPickerField(
      label: Terms.todoGroup,
      icon: Icons.folder_outlined,
      value: selected?.name,
      placeholder: selectedId == null ? '기본 ${Terms.todoGroup}' : null,
      errorText: groups.hasError
          ? '${Terms.todoGroup.withJosa('을', '를')} 불러오지 못했습니다'
          : null,
      onTap: locked || !groups.hasValue
          ? null
          : () async {
              final picked = await showTodoGroupPicker(
                context,
                groups: list,
                selectedId: selected?.id,
              );
              if (picked != null) onChanged(picked);
            },
    );
  }
}

/// 할 일 그룹을 고르는 대화상자. 고른 그룹 id, 닫으면 null
Future<String?> showTodoGroupPicker(
  BuildContext context, {
  required List<TodoGroupRead> groups,
  String? selectedId,
}) {
  return showAppChoiceDialog<String>(
    context,
    title: '${Terms.todoGroup} 고르기',
    content: '${Terms.todo.withJosa('을', '를')} 넣을 ${Terms.todoGroup}입니다.',
    selected: selectedId,
    choices: [
      for (final group in groups)
        AppDialogChoice(value: group.id, label: group.name),
    ],
  );
}
