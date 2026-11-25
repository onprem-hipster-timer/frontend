import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/api/rest/export.dart';

extension TodoStatusUI on TodoStatus {
  IconData get icon => switch (this) {
    TodoStatus.unscheduled => Icons.circle_outlined,
    TodoStatus.scheduled => Icons.schedule,
    TodoStatus.done => Icons.check_circle,
    TodoStatus.cancelled => Icons.cancel,
    TodoStatus.$unknown => Icons.help_outline,
  };

  Color color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      TodoStatus.unscheduled || TodoStatus.$unknown => scheme.onSurfaceVariant,
      TodoStatus.scheduled => scheme.primary,
      TodoStatus.done => AppColors.of(context).success,
      TodoStatus.cancelled => scheme.error,
    };
  }

  String get label => switch (this) {
    TodoStatus.unscheduled => '미예정',
    TodoStatus.scheduled => '예정됨',
    TodoStatus.done => '완료',
    TodoStatus.cancelled => '취소',
    TodoStatus.$unknown => '알 수 없음',
  };
}

/// 할 일 상태 아이콘. 누르면 4가지 상태(미예정, 예정됨, 완료, 취소)를 고르는 메뉴가 열리고,
/// 고른 상태로 [onSelected]를 부른다.
class TodoStatusSelectorView extends StatelessWidget {
  const TodoStatusSelectorView({
    super.key,
    required this.status,
    this.iconSize = 24.0,
    required this.onSelected,
  });

  /// 지금 상태. 아이콘과 메뉴에서 골라져 있는 항목
  final TodoStatus status;

  /// 아이콘 크기 (기본값: 24.0)
  final double iconSize;

  final ValueChanged<TodoStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TodoStatus>(
      initialValue: status,
      onSelected: onSelected,
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
      child: Icon(status.icon, color: status.color(context), size: iconSize),
    );
  }
}
