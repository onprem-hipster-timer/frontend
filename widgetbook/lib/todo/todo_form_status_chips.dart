import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_form_status_chips.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _statuses = {
  '미예정': TodoStatus.unscheduled,
  '예정됨': TodoStatus.scheduled,
  '완료': TodoStatus.done,
  '취소': TodoStatus.cancelled,
};

@widgetbook.UseCase(
  name: '할 일 상태 고르기',
  type: TodoFormStatusChips,
  path: '[할 일]',
)
Widget todoFormStatusChips(BuildContext context) {
  final status = context.knobs.object.dropdown(
    label: '처음 상태',
    description: '미예정과 예정됨은 마감일로 정해지므로 둘 다 "진행 중"으로 보인다',
    options: _statuses.keys.toList(),
  );
  // 할 일 폼 시트의 입력 칸 여백. 노브를 바꾸면 그 상태에서 다시 시작한다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: _StatusDemo(key: ValueKey(status), initial: _statuses[status]!),
  );
}

/// 칩을 누르면 바로 골라지도록 상태를 들고 있는다
class _StatusDemo extends StatefulWidget {
  const _StatusDemo({super.key, required this.initial});

  final TodoStatus initial;

  @override
  State<_StatusDemo> createState() => _StatusDemoState();
}

class _StatusDemoState extends State<_StatusDemo> {
  late TodoStatus _status = widget.initial;

  @override
  Widget build(BuildContext context) {
    return TodoFormStatusChips(
      selected: _status,
      onChanged: (status) => setState(() => _status = status),
    );
  }
}
