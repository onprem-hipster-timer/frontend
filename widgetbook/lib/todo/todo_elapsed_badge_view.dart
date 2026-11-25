import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_elapsed_badge_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '누적 집중 시간', type: TodoElapsedBadgeView, path: '[할 일]')
Widget todoElapsedBadgeView(BuildContext context) {
  final knobs = context.knobs;
  final finished = knobs.int.slider(
    label: '끝난 타이머 시간(분)',
    description: '하위 할 일까지 합친 시간. 도는 타이머도 없고 0이면 배지가 없다',
    initialValue: 95,
    max: 1500,
  );
  final running = knobs.boolean(
    label: '타이머 도는 중',
    description: '하위 할 일까지 중 타이머가 돌고 있으면 강조 색이고 1초마다 늘어난다',
  );
  final active = knobs.int.slider(
    label: '도는 타이머 경과 시간(초)',
    initialValue: 754,
    max: 3600,
  );
  // 앱에서는 할 일 줄의 제목 아래, 남은 시간 칩 옆에 붙는다
  return Center(
    child: TodoElapsedBadgeView(
      finishedSeconds: finished * 60,
      activeSeconds: running ? active : null,
    ),
  );
}
