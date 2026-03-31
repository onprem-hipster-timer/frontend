import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import '../providers/todo_provider.dart';

extension TodoStatusUI on TodoStatus {
  IconData get icon => switch (this) {
    TodoStatus.unscheduled => Icons.circle_outlined,
    TodoStatus.scheduled => Icons.schedule,
    TodoStatus.done => Icons.check_circle,
    TodoStatus.cancelled => Icons.cancel,
    TodoStatus.$unknown => Icons.help_outline,
  };

  Color color(BuildContext context) => switch (this) {
    TodoStatus.unscheduled => Colors.grey,
    TodoStatus.scheduled => Colors.blue,
    TodoStatus.done => Colors.green,
    TodoStatus.cancelled => Colors.red,
    TodoStatus.$unknown => Colors.grey,
  };

  String get label => switch (this) {
    TodoStatus.unscheduled => '미예정',
    TodoStatus.scheduled => '예정됨',
    TodoStatus.done => '완료',
    TodoStatus.cancelled => '취소',
    TodoStatus.$unknown => '알 수 없음',
  };
}

/// Todo 상태 선택 위젯
///
/// 4가지 상태(미예정, 예정됨, 완료, 취소)를 관리할 수 있는 커스텀 상태 컨트롤러입니다.
/// 사용자가 아이콘을 탭하면 상태 선택 팝업 메뉴가 표시됩니다.
class TodoStatusSelector extends ConsumerWidget {
  /// Todo 데이터
  final TodoRead todo;

  /// 아이콘 크기 (기본값: 24.0)
  final double iconSize;

  const TodoStatusSelector({
    super.key,
    required this.todo,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<TodoStatus>(
      initialValue: todo.status,
      onSelected: (TodoStatus newStatus) async {
        if (newStatus != todo.status) {
          await ref
              .read(todoMutationsProvider.notifier)
              .changeStatus(todo.id, newStatus);
        }
      },
      itemBuilder: (BuildContext context) {
        return TodoStatus.values
            .where((status) => status != TodoStatus.$unknown)
            .map((TodoStatus status) {
              return PopupMenuItem<TodoStatus>(
                value: status,
                child: Row(
                  children: [
                    Icon(status.icon, color: status.color(context), size: 20),
                    const SizedBox(width: 12),
                    Text(status.label),
                  ],
                ),
              );
            })
            .toList();
      },
      child: Icon(
        todo.status.icon,
        color: todo.status.color(context),
        size: iconSize,
      ),
    );
  }
}
