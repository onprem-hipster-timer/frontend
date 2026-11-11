import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 완료·취소가 아닌 "진행 중" 상태인지 (미예정과 예정됨을 하나로 본다)
bool isActiveTodoStatus(TodoStatus status) =>
    status == TodoStatus.unscheduled || status == TodoStatus.scheduled;

/// 할 일 폼의 상태 고르기: 진행 중·완료·취소
///
/// 미예정·예정됨은 서버가 마감일로 정하므로 "진행 중" 하나로 보여 준다.
class TodoFormStatusChips extends StatelessWidget {
  const TodoFormStatusChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TodoStatus selected;
  final ValueChanged<TodoStatus> onChanged;

  static const _choices = [
    TodoStatus.unscheduled,
    TodoStatus.done,
    TodoStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader('상태'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in _choices)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _StatusChip(
                    status: status,
                    selected: status == TodoStatus.unscheduled
                        ? isActiveTodoStatus(selected)
                        : selected == status,
                    onPrimary: onPrimary,
                    onSelected: () => onChanged(status),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.selected,
    required this.onPrimary,
    required this.onSelected,
  });

  final TodoStatus status;
  final bool selected;
  final Color onPrimary;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    return ChoiceChip(
      label: Text(isActiveTodoStatus(status) ? '진행 중' : status.label),
      selected: selected,
      onSelected: (value) {
        if (value) onSelected();
      },
      avatar: Icon(status.icon, size: 18, color: selected ? onPrimary : color),
      selectedColor: color,
      checkmarkColor: onPrimary,
    );
  }
}
