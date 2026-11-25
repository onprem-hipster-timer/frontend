import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/timer.dart'
    show TimerDashboardControlsView, TimerDashboardModel, TimerDashboardView;
import 'package:momeet/shared/api/rest/export.dart';

/// 체험하기의 타이머. 앱의 타이머 대시보드([TimerDashboardView])에 진행 중인 [timer]를 [remaining]만큼 남은
/// 채로 보인다. 남은 시간이 0이면 앱처럼 시간 종료다.
///
/// 누르는 것은 모두 반응하지 않는다. 작업 제목 옆 공유 설정처럼 앱의 데이터를 읽는 것이 있어 통째로 막는다
class TrialTimerDashboard extends StatelessWidget {
  const TrialTimerDashboard({
    super.key,
    required this.timer,
    required this.remaining,
  });

  final TimerRead timer;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final timeUp = remaining == Duration.zero;
    final model = TimerDashboardModel(
      activeTimer: timer,
      remaining: remaining,
      breakSession: null,
      breakRemaining: Duration.zero,
      // 다른 타이머가 없어 '새 타이머'와 갤러리를 두지 않는다
      myTimers: const [],
      breakBlocked: false,
      pageNow: timer.startedAt ?? timer.createdAt,
      timeUp: timeUp,
    );
    // 조작 단추(떠 있는 단추 둘)가 화면을 떠날 때 날아가지 않게 Hero를 끈다
    return HeroMode(
      enabled: false,
      child: IgnorePointer(
        child: TimerDashboardView(
          model: model,
          onFocusTimer: (_) {},
          onTodoStatusSelected: (_) {},
          addTimerBuilder: (_, _) => const SizedBox.shrink(),
          controlsBuilder:
              ({
                required breakSelected,
                required pendingDuration,
                required pendingBreakDuration,
              }) => TimerDashboardControlsView(
                onBreak: false,
                breakOver: false,
                activeTimer: timer,
                starting: false,
                timeUp: timeUp,
                breakSelected: breakSelected,
                onEndBreak: () {},
                onStart: () {},
                onStartBreak: null,
                onStop: () {},
                onPause: () {},
                onResume: () {},
                onExtend: () {},
              ),
        ),
      ),
    );
  }
}
