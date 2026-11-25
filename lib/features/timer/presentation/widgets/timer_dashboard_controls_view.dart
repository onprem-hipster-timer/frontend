import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_control_button.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 대시보드 맨 아래의 조작 버튼
///
/// 휴식 중이면 휴식 끝내기(끝났으면 확인)를, 아니면 [TimerControlButton]을 둔다.
class TimerDashboardControlsView extends StatelessWidget {
  const TimerDashboardControlsView({
    super.key,
    required this.onBreak,
    required this.breakOver,
    required this.activeTimer,
    required this.starting,
    required this.timeUp,
    required this.breakSelected,
    required this.onEndBreak,
    required this.onStart,
    required this.onStartBreak,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onExtend,
  });

  /// 휴식 중인지
  final bool onBreak;
  final bool breakOver;
  final TimerRead? activeTimer;

  /// 새 타이머를 시작하는 중
  final bool starting;
  final bool timeUp;
  final bool breakSelected;
  final VoidCallback onEndBreak;
  final VoidCallback onStart;

  /// 휴식을 시작할 수 없으면 null
  final VoidCallback? onStartBreak;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onExtend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (onBreak) {
      return FloatingActionButton(
        onPressed: onEndBreak,
        tooltip: breakOver ? '확인' : '${Terms.rest} 끝내기',
        backgroundColor: colorScheme.tertiary,
        child: Icon(
          breakOver ? Icons.check : Icons.stop,
          color: colorScheme.onTertiary,
        ),
      );
    }
    return TimerControlButton(
      activeTimer: activeTimer,
      starting: starting,
      timeUp: timeUp,
      breakSelected: breakSelected,
      onStart: onStart,
      onStartBreak: onStartBreak,
      onStop: onStop,
      onPause: onPause,
      onResume: onResume,
      onExtend: onExtend,
    );
  }
}
