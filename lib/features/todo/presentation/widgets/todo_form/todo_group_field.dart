import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_group_field_view.dart';

/// 할 일 폼의 할 일 그룹 칸. 누르면 그룹을 고르는 대화상자를 연다.
///
/// [selectedId]가 null이면 기본 그룹을 보인다(보내지 않으면 서버가 기본 그룹에 넣는다).
class TodoGroupField extends ConsumerWidget {
  const TodoGroupField({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.locked = false,
    this.pickerContent,
  });

  final String? selectedId;
  final ValueChanged<String> onChanged;

  /// 고르는 대화상자의 안내. 없으면 새 할 일을 넣을 그룹이라고 안내한다
  final String? pickerContent;

  /// 바꿀 수 없게 한다(하위 할 일은 상위 할 일의 그룹을 따른다)
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TodoGroupFieldView(
      groups: ref.watch(todoGroupsProvider),
      selectedId: selectedId,
      onChanged: onChanged,
      locked: locked,
      pickerContent: pickerContent,
    );
  }
}
