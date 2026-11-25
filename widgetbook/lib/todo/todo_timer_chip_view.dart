import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_chip_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '타이머 남은 시간', type: TodoTimerChipView, path: '[할 일]')
Widget todoTimerChipView(BuildContext context) {
  final remaining = context.knobs.int.slider(
    label: '남은 시간(초)',
    description: '한 시간 이상이면 시:분:초로 쓴다. 0이면 다 된 타이머라 빨간색이다',
    initialValue: 1499,
    max: 7200,
  );
  // 앱에서는 할 일 줄의 제목 아래, 그 할 일로 시작한 타이머가 돌거나 멈춰 있을 때만 붙는다.
  // 누르면 타이머 화면으로 간다
  return Center(child: TodoTimerChipView(remainingSeconds: remaining));
}
