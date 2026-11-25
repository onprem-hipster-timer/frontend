import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_child_count_badge.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '하위 할 일 개수', type: TodoChildCountBadge, path: '[할 일]')
Widget todoChildCountBadge(BuildContext context) {
  final count = context.knobs.int.slider(
    label: '하위 할 일 수',
    description: '할 일 줄의 제목 아래, 하위 할 일이 있을 때만 붙는다',
    initialValue: 3,
    min: 1,
    max: 120,
  );
  return Center(child: TodoChildCountBadge(count: count));
}
