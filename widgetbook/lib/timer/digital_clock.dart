import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/digital_clock.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '남은 시간 시계', type: DigitalClock, path: '[타이머]')
Widget digitalClock(BuildContext context) {
  final knobs = context.knobs;
  final minutes = knobs.int.slider(
    label: '분',
    initialValue: 12,
    max: 180,
    divisions: 180,
  );
  final seconds = knobs.int.slider(
    label: '초',
    initialValue: 34,
    max: 59,
    divisions: 59,
  );
  final state = knobs.object.dropdown(
    label: '상태',
    options: const ['진행 중', '시간 종료', '대기 중'],
    description: '대기 중은 타이머 없이 다이얼로 고른 시간을 흐리게 보인다',
  );
  final compact = knobs.boolean(
    label: '낮은 화면',
    description: '높이 400보다 낮은 칸(가로 휴대폰)에서 줄인 글자',
  );
  return Center(
    child: DigitalClock(
      duration: Duration(minutes: minutes, seconds: seconds),
      timeUp: state == '시간 종료',
      idle: state == '대기 중',
      compact: compact,
    ),
  );
}
