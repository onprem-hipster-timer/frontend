import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_timer.dart';

@widgetbook.UseCase(name: '타이머 다이얼', type: TimerDial, path: '[타이머]')
Widget timerDial(BuildContext context) {
  final knobs = context.knobs;
  final state = knobs.object.dropdown(
    label: '상태',
    options: SampleTimerState.values,
    labelBuilder: (state) => state.label,
    initialOption: SampleTimerState.running,
    description: '대기 중에는 다이얼을 눌러 끌어서 시간을 고른다',
  );
  final rest = knobs.boolean(label: '휴식 고름', description: '대기 중 휴식을 고르면 3차색');
  final allocated = knobs.int.slider(
    label: '정한 시간(분)',
    initialValue: 25,
    min: 1,
    max: 180,
    divisions: 179,
    description: '60분이 넘으면 한 바퀴가 60분 단위로 늘어난다(90분이면 120분)',
  );
  final minutes = knobs.int.slider(
    label: '남은 분',
    initialValue: 12,
    max: 180,
    divisions: 180,
  );
  final seconds = knobs.int.slider(
    label: '남은 초',
    initialValue: 34,
    max: 59,
    divisions: 59,
  );
  final labels = knobs.boolean(
    label: '눈금 숫자',
    initialValue: true,
    description: '아주 작은 화면의 집중 보기는 숫자 없이 원판을 크게 그린다',
  );
  final total = Duration(minutes: allocated);
  final remaining = Duration(minutes: minutes, seconds: seconds);
  final color = sampleDialColor(
    Theme.of(context).colorScheme,
    state,
    rest: rest,
  );
  // 앱에서는 대시보드의 남는 높이를 모두 쓰므로 폭 가득 정사각형으로 둔다
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: switch (state) {
          SampleTimerState.idle => _PickingDial(
            initial: remaining,
            color: color,
            labels: labels,
            label: rest ? '휴식 시간' : '집중 시간',
          ),
          SampleTimerState.timeUp => TimerDial(
            remaining: Duration.zero,
            face: dialFaceFor(total),
            color: color,
            labels: labels,
          ),
          _ => TimerDial(
            remaining: remaining > total ? total : remaining,
            face: dialFaceFor(total),
            color: color,
            labels: labels,
          ),
        },
      ),
    ),
  );
}

/// 대기 중 다이얼. 끌어서 고른 시간을 들고 있어 원판이 따라 움직인다
class _PickingDial extends StatefulWidget {
  const _PickingDial({
    required this.initial,
    required this.color,
    required this.labels,
    required this.label,
  });

  final Duration initial;
  final Color color;
  final bool labels;
  final String label;

  @override
  State<_PickingDial> createState() => _PickingDialState();
}

class _PickingDialState extends State<_PickingDial> {
  late Duration _value = _clamped(widget.initial);

  static Duration _clamped(Duration value) =>
      snapDialDuration(value, dialFaceFor(value));

  @override
  void didUpdateWidget(_PickingDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) _value = _clamped(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return TimerDial(
      remaining: _value,
      color: widget.color,
      labels: widget.labels,
      label: widget.label,
      onChanged: (value) => setState(() => _value = value),
    );
  }
}
