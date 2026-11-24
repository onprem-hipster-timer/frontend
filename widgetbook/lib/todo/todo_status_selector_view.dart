import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
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
  name: '할 일 상태 메뉴',
  type: TodoStatusSelectorView,
  path: '[할 일]',
)
Widget todoStatusSelectorView(BuildContext context) {
  final status = context.knobs.object.dropdown(
    label: '상태',
    description: '아이콘을 누르면 상태 메뉴가 열리고, 고른 상태가 바로 아이콘에 보인다',
    options: _statuses.keys.toList(),
  );
  // 앱에서는 할 일 줄의 제목 앞, 일시정지한 타이머의 작업 제목 앞에 놓인다.
  // 노브를 바꾸면 고른 상태를 버리고 노브 값으로 돌아간다
  return Center(
    child: _StatusDemo(key: ValueKey(status), initial: _statuses[status]!),
  );
}

/// 메뉴에서 고른 상태가 아이콘에 보이도록 상태를 들고 있는다
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
    return TodoStatusSelectorView(
      status: _status,
      onSelected: (status) => setState(() => _status = status),
    );
  }
}
