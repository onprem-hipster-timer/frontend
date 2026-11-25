import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_start_button_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '타이머 시작',
  type: TodoTimerStartButtonView,
  path: '[할 일]',
)
Widget todoTimerStartButtonView(BuildContext context) {
  final starting = context.knobs.boolean(
    label: '시작하는 중',
    description: '새 타이머를 시작하고 응답을 기다리는 동안 누를 수 없다',
  );
  // 앱에서는 할 일 줄 오른쪽 수정·삭제 버튼 앞에 놓이고, 그 할 일로 시작한 타이머가 돌거나 멈춰 있으면 없다.
  // 누르면 그 할 일을 고른 새 타이머 시트가 열린다
  return Center(
    child: TodoTimerStartButtonView(starting: starting, onPressed: () {}),
  );
}
