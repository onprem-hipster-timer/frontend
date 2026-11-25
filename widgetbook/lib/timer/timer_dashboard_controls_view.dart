import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_controls_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

/// 대시보드 상태. 타이머 상태에 휴식 중·휴식 종료를 더한다
enum _State {
  idle('대기 중'),
  running('진행 중'),
  paused('일시정지'),
  timeUp('시간 종료'),
  onBreak('휴식 중'),
  breakOver('휴식 종료');

  const _State(this.label);

  final String label;
}

@widgetbook.UseCase(
  name: '대시보드 조작 버튼',
  type: TimerDashboardControlsView,
  path: '[타이머]',
)
Widget timerDashboardControlsView(BuildContext context) {
  final knobs = context.knobs;
  final state = knobs.object.dropdown(
    label: '상태',
    options: _State.values,
    labelBuilder: (state) => state.label,
    initialOption: _State.onBreak,
    description: '휴식 중에는 휴식 끝내기를, 휴식 시간이 다 되면 확인을 둔다',
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
  final onBreak = state == _State.onBreak || state == _State.breakOver;
  final activeTimer = switch (state) {
    _State.running || _State.timeUp => sampleTimer(),
    _State.paused => sampleTimer(status: TimerStatus.paused),
    _ => null,
  };
  // 앱에서는 대시보드 맨 아래 가운데, 상태 문구 아래에 놓인다
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: TimerDashboardControlsView(
        onBreak: onBreak,
        breakOver: state == _State.breakOver,
        activeTimer: activeTimer,
        starting: starting,
        timeUp: state == _State.timeUp,
        breakSelected: breakSelected,
        onEndBreak: () {},
        onStart: () {},
        onStartBreak: breakAvailable ? () {} : null,
        onStop: () {},
        onPause: () {},
        onResume: () {},
        onExtend: () {},
      ),
    ),
  );
}
