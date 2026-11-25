import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
import '../providers/todo_provider.dart';

export 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart'
    show TodoStatusUI;

/// Todo 상태 선택 위젯
///
/// 4가지 상태(미예정, 예정됨, 완료, 취소)를 관리할 수 있는 커스텀 상태 컨트롤러입니다.
/// 사용자가 아이콘을 탭하면 상태 선택 팝업 메뉴가 표시됩니다.
class TodoStatusSelector extends ConsumerWidget {
  /// Todo 데이터
  final TodoRead todo;

  /// 아이콘 크기 (기본값: 24.0)
  final double iconSize;

  /// 상태를 바꾼 뒤 서버가 돌려준 Todo로 불린다.
  final ValueChanged<TodoRead>? onChanged;

  const TodoStatusSelector({
    super.key,
    required this.todo,
    this.iconSize = 24.0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TodoStatusSelectorView(
      status: todo.status,
      iconSize: iconSize,
      onSelected: (TodoStatus newStatus) async {
        if (newStatus != todo.status) {
          final updated = await updateTodoMutation.run(
            ref,
            (tsx) => tsx
                .get(todoMutationsProvider.notifier)
                .changeStatus(todo.id, newStatus),
          );
          onChanged?.call(updated);
        }
      },
    );
  }
}
