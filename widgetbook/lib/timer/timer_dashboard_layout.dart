import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/current_task_display.dart';
import 'package:momeet/features/timer/presentation/widgets/digital_clock.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_actions.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_layout.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_gallery.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_timer.dart';

@widgetbook.UseCase(name: '타이머 대시보드', type: TimerDashboardLayout, path: '[타이머]')
Widget timerDashboardLayout(BuildContext context) {
  final knobs = context.knobs;
  final state = knobs.object.dropdown(
    label: '상태',
    options: SampleTimerState.values,
    labelBuilder: (state) => state.label,
    initialOption: SampleTimerState.running,
    description: '대기 중에는 다이얼을 끌어 시간을 고르고 집중·휴식을 고른다',
  );
  final count = knobs.int.slider(
    label: '내 활성 타이머 수',
    initialValue: 1,
    min: 1,
    max: 4,
    description: '둘 이상이면 다이얼 자리를 옆으로 넘겨 보는 갤러리가 된다(대기 중에는 0개)',
  );
  final allocated = knobs.int.slider(
    label: '정한 시간(분)',
    initialValue: 25,
    min: 1,
    max: 180,
    divisions: 179,
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
  final focus = knobs.boolean(
    label: '집중 보기',
    description: '아주 작은 화면에서는 앱바 없이 시계를 다이얼 가운데에 겹친다',
  );
  final landscape = knobs.boolean(
    label: '가로 휴대폰',
    description: '높이 400보다 낮고 넓은 칸은 다이얼을 왼쪽에 둔다. 800x360 칸을 화면 폭에 맞춰 줄여 보인다',
  );
  // 작업 제목 뒤 공유 설정 버튼을 누르면 시트가 열린다
  final dashboard = SampleProviderScope(
    overrides: sampleShareOverrides(sampleTimer()),
    child: _Dashboard(
      state: state,
      count: count,
      allocated: Duration(minutes: allocated),
      remaining: Duration(minutes: minutes, seconds: seconds),
      focus: focus,
    ),
  );
  if (!landscape) return dashboard;
  return Center(
    child: FittedBox(
      child: SizedBox(width: 800, height: 360, child: dashboard),
    ),
  );
}

/// 대시보드에 보이는 타이머 하나와 그 상태
typedef _Shown = ({
  TimerRead timer,
  SampleTimerState state,
  Duration allocated,
  Duration remaining,
});

/// 다이얼로 고른 시간, 집중·휴식 고르기, 갤러리에서 넘긴 타이머를 들고 있어 앱처럼 반응한다
class _Dashboard extends StatefulWidget {
  const _Dashboard({
    required this.state,
    required this.count,
    required this.allocated,
    required this.remaining,
    required this.focus,
  });

  final SampleTimerState state;
  final int count;
  final Duration allocated;
  final Duration remaining;
  final bool focus;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  Duration _pendingFocus = const Duration(minutes: 25);
  Duration _pendingBreak = const Duration(minutes: 5);
  Duration? _dragPreview;
  bool _breakSelected = false;
  String _focusedId = 'timer-0';

  /// 첫 타이머는 노브 값, 나머지는 고정 예시
  List<_Shown> get _timers {
    final state = widget.state;
    if (state == SampleTimerState.idle) return const [];
    final allocated = widget.allocated;
    final remaining = state == SampleTimerState.timeUp
        ? Duration.zero
        : widget.remaining > allocated
        ? allocated
        : widget.remaining;
    const otherAllocated = Duration(minutes: 50);
    const otherRemaining = Duration(minutes: 40);
    return [
      (
        timer: sampleTimer(
          allocated: allocated,
          remaining: remaining,
          status: state == SampleTimerState.paused
              ? TimerStatus.paused
              : TimerStatus.running,
        ),
        state: state,
        allocated: allocated,
        remaining: remaining,
      ),
      for (var i = 1; i < widget.count; i++)
        (
          timer: sampleTimer(
            index: i,
            allocated: otherAllocated,
            remaining: otherRemaining,
          ),
          state: SampleTimerState.running,
          allocated: otherAllocated,
          remaining: otherRemaining,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focus = widget.focus;
    final timers = _timers;
    final shown = timers.isEmpty
        ? null
        : timers.firstWhere(
            (shown) => shown.timer.id == _focusedId,
            orElse: () => timers.first,
          );
    final state = shown?.state ?? SampleTimerState.idle;
    final idle = shown == null;
    final rest = idle && _breakSelected;
    final pending = rest ? _pendingBreak : _pendingFocus;

    Widget dialOf(_Shown shown) => TimerDial(
      remaining: shown.remaining,
      face: dialFaceFor(shown.allocated),
      color: sampleDialColor(colorScheme, shown.state),
      labels: !focus,
    );

    final focusedDial = shown == null
        ? TimerDial(
            remaining: pending,
            color: sampleDialColor(colorScheme, state, rest: rest),
            labels: !focus,
            label: rest ? '휴식 시간' : '집중 시간',
            onPreview: (value) => setState(() => _dragPreview = value),
            onChanged: (value) => setState(() {
              if (rest) {
                _pendingBreak = value;
              } else {
                _pendingFocus = value;
              }
            }),
          )
        : dialOf(shown);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = SizedBox(
          height: TimerDashboardLayout.isShort(constraints) ? 8 : 16,
        );
        return TimerDashboardLayout(
          constraints: constraints,
          dial: timers.length >= 2
              ? TimerGallery(
                  timers: [for (final shown in timers) shown.timer],
                  focusedId: shown?.timer.id,
                  arrows: false,
                  onFocus: (id) => setState(() => _focusedId = id),
                  pageBuilder: (timer) => timer.id == shown?.timer.id
                      ? focusedDial
                      : dialOf(timers.firstWhere((s) => s.timer == timer)),
                )
              : focusedDial,
          // 앱의 '새 타이머' 칩은 누르면 시작 시트를 여는 Provider 위젯이라 같은 모양의 칩으로 둔다
          addTimer: idle
              ? null
              : focus
              ? IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '새 타이머',
                  onPressed: () {},
                )
              : ActionChip(
                  avatar: const Icon(Icons.add),
                  label: const Text('새 타이머'),
                  onPressed: () {},
                ),
          header: CurrentTaskDisplay(timer: shown?.timer),
          clock: DigitalClock(
            duration: shown?.remaining ?? _dragPreview ?? pending,
            timeUp: state == SampleTimerState.timeUp,
            idle: idle,
            compact: TimerDashboardLayout.isShort(constraints),
          ),
          focus: focus,
          focusLeading: IconButton(
            icon: const Icon(Icons.menu),
            tooltip: '메뉴',
            onPressed: () {},
          ),
          focusActions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: '타이머 목록',
              onPressed: () {},
            ),
          ],
          controls: [
            TimerDashboardActions(
              caption: sampleCaption(state),
              alert: state == SampleTimerState.timeUp,
              gap: gap,
              focus: focus,
              breakSelected: idle ? _breakSelected : null,
              onBreakSelected: (value) =>
                  setState(() => _breakSelected = value),
              controls: sampleControlButton(
                state,
                breakSelected: _breakSelected,
              ),
            ),
          ],
        );
      },
    );
  }
}
