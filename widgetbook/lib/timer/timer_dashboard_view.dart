import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/domain/break_session.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart'
    show blocksBreak;
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_controls_view.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_model.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/widgets/shell_scope.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
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

@widgetbook.UseCase(name: '타이머 대시보드', type: TimerDashboardView, path: '[타이머]')
Widget timerDashboardView(BuildContext context) {
  final knobs = context.knobs;
  final state = knobs.object.dropdown(
    label: '상태',
    options: _State.values,
    labelBuilder: (state) => state.label,
    initialOption: _State.running,
    description: '대기 중에는 다이얼을 끌거나 시계를 눌러 시간을 고르고 집중·휴식을 고른다',
  );
  final count = knobs.int.slider(
    label: '내 활성 타이머 수',
    initialValue: 1,
    min: 1,
    max: 4,
    description: '둘 이상이면 다이얼 자리를 옆으로 넘겨 보는 갤러리가 된다(대기 중·휴식 중에는 없다)',
  );
  final allocated = knobs.int.slider(
    label: '정한 시간(분)',
    initialValue: 25,
    min: 1,
    max: 180,
    divisions: 179,
    description: '휴식 중이면 휴식 길이',
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
  final fromTodo = knobs.boolean(
    label: '할 일에서 시작',
    description: '할 일에서 시작한 타이머는 제목 앞에 할 일 상태를 두고, 눌러 바꿀 수 있다',
  );
  final starting = knobs.boolean(
    label: '시작하는 중',
    description: '새 타이머를 시작하고 응답을 기다리는 동안 시작 버튼을 누를 수 없다',
  );
  final focus = knobs.boolean(
    label: '집중 보기',
    description: '아주 작은 화면에서는 앱바 없이 시계를 다이얼 가운데에 겹친다',
  );
  // 작업 제목 뒤 공유 설정 버튼을 누르면 시트가 열린다
  return SampleProviderScope(
    overrides: sampleShareOverrides(sampleTimer()),
    child: ShellScope(
      compact: focus,
      current: 0,
      onSelect: (_) {},
      openTabs: () {},
      child: _Dashboard(
        state: state,
        count: count,
        allocated: Duration(minutes: allocated),
        remaining: Duration(minutes: minutes, seconds: seconds),
        fromTodo: fromTodo,
        starting: starting,
      ),
    ),
  );
}

/// 갤러리에서 넘긴 타이머와 고른 할 일 상태를 들고 있어 앱처럼 반응한다
class _Dashboard extends StatefulWidget {
  const _Dashboard({
    required this.state,
    required this.count,
    required this.allocated,
    required this.remaining,
    required this.fromTodo,
    required this.starting,
  });

  final _State state;
  final int count;
  final Duration allocated;
  final Duration remaining;
  final bool fromTodo;
  final bool starting;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  String _focusedId = 'timer-0';
  TodoStatus _todoStatus = TodoStatus.scheduled;

  /// 견본 타이머를 시작한 시각. 이때 보면 각 타이머의 남은 시간이 정한 값 그대로다
  DateTime get _now => sampleTimer().startedAt!;

  /// 첫 타이머는 노브 값, 나머지는 고정 예시
  List<TimerRead> _timers(Duration remaining) {
    final status = widget.state == _State.paused
        ? TimerStatus.paused
        : TimerStatus.running;
    return [
      sampleTimer(
        allocated: widget.allocated,
        remaining: remaining,
        status: status,
        todo: widget.fromTodo ? sampleTodo(status: _todoStatus) : null,
      ),
      for (var i = 1; i < widget.count; i++)
        sampleTimer(
          index: i,
          allocated: const Duration(minutes: 50),
          remaining: const Duration(minutes: 40),
        ),
    ];
  }

  TimerDashboardModel get _model {
    final state = widget.state;
    final allocated = widget.allocated;
    final remaining = widget.remaining > allocated
        ? allocated
        : widget.remaining;
    final now = _now;
    if (state == _State.onBreak || state == _State.breakOver) {
      return TimerDashboardModel(
        activeTimer: null,
        remaining: Duration.zero,
        breakSession: BreakSession(endAt: now.add(remaining), total: allocated),
        breakRemaining: state == _State.breakOver ? Duration.zero : remaining,
        myTimers: const [],
        breakBlocked: false,
        pageNow: now,
        timeUp: false,
      );
    }
    final timers = state == _State.idle
        ? const <TimerRead>[]
        : _timers(state == _State.timeUp ? Duration.zero : remaining);
    final shown = timers
        .where((timer) => timer.id == _focusedId)
        .followedBy(timers)
        .firstOrNull;
    final shownRemaining = shown == null
        ? Duration.zero
        : displayRemaining(shown, now);
    return TimerDashboardModel(
      activeTimer: shown,
      remaining: shownRemaining,
      breakSession: null,
      breakRemaining: Duration.zero,
      myTimers: timers,
      breakBlocked: blocksBreak(timers, now),
      pageNow: now,
      timeUp: shown != null && isTimeUp(shown, now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    return TimerDashboardView(
      model: model,
      onFocusTimer: (id) => setState(() => _focusedId = id),
      onTodoStatusSelected: (status) => setState(() => _todoStatus = status),
      // 앱의 '새 타이머' 칩은 누르면 시작 시트를 여는 Provider 위젯이라 같은 모양의 칩으로 둔다
      addTimerBuilder: (initialDuration, icon) => icon
          ? IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: '새 타이머',
              onPressed: widget.starting ? null : () {},
            )
          : ActionChip(
              avatar: const Icon(Icons.add),
              label: const Text('새 타이머'),
              onPressed: widget.starting ? null : () {},
            ),
      controlsBuilder:
          ({
            required breakSelected,
            required pendingDuration,
            required pendingBreakDuration,
          }) => TimerDashboardControlsView(
            onBreak: model.onBreak,
            breakOver: model.breakOver,
            activeTimer: model.activeTimer,
            starting: widget.starting,
            timeUp: model.timeUp,
            breakSelected: breakSelected,
            onEndBreak: () {},
            onStart: () {},
            onStartBreak: model.breakBlocked ? null : () {},
            onStop: () {},
            onPause: () {},
            onResume: () {},
            onExtend: () {},
          ),
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
    );
  }
}
