import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_root_drop_target_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '루트로 이동 칸',
  type: TodoRootDropTargetView,
  path: '[할 일]',
)
Widget todoRootDropTargetView(BuildContext context) {
  final highlighted = context.knobs.boolean(
    label: '하위 할 일을 끌어 올림',
    description: '하위 할 일을 길게 눌러 끌어 이 칸 위에 올리면 강조하고, 놓으면 맨 위 할 일이 된다',
  );
  // 앱에서는 할 일 목록 화면의 트리 바로 위, 좌우 16 여백 안에 놓인다
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: TodoRootDropTargetView(highlighted: highlighted),
    ),
  );
}
