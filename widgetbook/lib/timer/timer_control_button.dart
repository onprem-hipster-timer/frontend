import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_control_button.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

@widgetbook.UseCase(name: '타이머 조작 버튼', type: TimerControlButton, path: '[타이머]')
Widget timerControlButton(BuildContext context) {
  final knobs = context.knobs;
  final state = knobs.object.dropdown(
    label: '상태',
    options: SampleTimerState.values,
    labelBuilder: (state) => state.label,
    initialOption: SampleTimerState.paused,
  );
  final breakSelected = knobs.boolean(
    label: '휴식 고름',
    description: '대기 중 작업 대신 휴식을 고르면 시작 버튼이 휴식을 시작한다',
  );
  final starting = knobs.boolean(
    label: '시작하는 중',
    description: '대기 중 새 타이머 시작을 누르고 응답을 기다리는 동안',
  );
  final breakAvailable = knobs.boolean(
    label: '휴식 가능',
    initialValue: true,
    description: '시간이 남은 채 도는 다른 내 타이머가 있으면 휴식 버튼이 없다',
  );
  // 앱에서는 대시보드 맨 아래 가운데에 놓인다
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: sampleControlButton(
        state,
        breakSelected: breakSelected,
        starting: starting,
        breakAvailable: breakAvailable,
      ),
    ),
  );
}
