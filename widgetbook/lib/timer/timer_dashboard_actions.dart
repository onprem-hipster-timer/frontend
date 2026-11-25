import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_actions.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

@widgetbook.UseCase(
  name: '다이얼 아래 조작 묶음',
  type: TimerDashboardActions,
  path: '[타이머]',
)
Widget timerDashboardActions(BuildContext context) {
  final knobs = context.knobs;
  final state = knobs.object.dropdown(
    label: '상태',
    options: SampleTimerState.values,
    labelBuilder: (state) => state.label,
    description: '대기 중에는 집중·휴식 고르기가 생긴다',
  );
  final focus = knobs.boolean(
    label: '집중 보기',
    description: '아주 작은 화면에서는 대기 중 고르기와 시작 버튼을 한 줄에 둔다',
  );
  // 앱에서는 대시보드 양옆 24 여백 안, 시계 아래 가운데에 놓인다
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Align(
      alignment: Alignment.topCenter,
      child: _Actions(state: state, focus: focus),
    ),
  );
}

/// 집중·휴식 고르기를 눌러 바꿀 수 있게 고른 값을 들고 있다
class _Actions extends StatefulWidget {
  const _Actions({required this.state, required this.focus});

  final SampleTimerState state;
  final bool focus;

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  bool _breakSelected = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final idle = state == SampleTimerState.idle;
    return TimerDashboardActions(
      caption: sampleCaption(state),
      alert: state == SampleTimerState.timeUp,
      gap: const SizedBox(height: 16),
      focus: widget.focus,
      breakSelected: idle ? _breakSelected : null,
      onBreakSelected: (value) => setState(() => _breakSelected = value),
      controls: sampleControlButton(state, breakSelected: _breakSelected),
    );
  }
}
