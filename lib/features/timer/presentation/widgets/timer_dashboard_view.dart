import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/domain/default_durations.dart';
import 'package:momeet/features/timer/presentation/widgets/current_task_display.dart';
import 'package:momeet/features/timer/presentation/widgets/digital_clock.dart';
import 'package:momeet/features/timer/presentation/widgets/duration_picker_sheet.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_actions.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_layout.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_model.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_gallery.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/widgets/shell_scope.dart';

/// 이 폭보다 좁으면 다이얼만 두고 타이머 목록은 바텀 시트로 연다
const timerWideLayoutMinWidth = 600.0;

/// 대시보드 맨 아래 조작 버튼. 대기 중 고른 모드(작업·휴식)와 모드마다 고른 시간을 받는다
typedef TimerDashboardControlsBuilder =
    Widget Function({
      required bool breakSelected,
      required Duration pendingDuration,
      required Duration pendingBreakDuration,
    });

/// 타이머 대시보드
///
/// 작업 제목, 다이얼, 디지털 시계, 상태 캡션, 제어 버튼을 위에서부터 둡니다. 다이얼이 남는 높이를 모두 씁니다.
/// 낮고 넓은 칸(가로 휴대폰)은 다이얼을 왼쪽에 두고 제목부터 나머지를 오른쪽에 둡니다([TimerDashboardLayout]).
/// 휴식 중이면 휴식을, 아니면 [model]의 활성 타이머를 보여 주고, 다이얼은 남은 시간만 보여 줍니다.
/// 활성 타이머가 둘 이상이면 다이얼 자리에 타이머마다 한 쪽씩 다이얼을 둔 갤러리([TimerGallery])를 두고,
/// 보이는 쪽의 타이머를 [onFocusTimer]로 알립니다. 활성 타이머가 있으면 굴리지 않는 '새 타이머' 칩
/// ([addTimerBuilder])을 둡니다. 휴식 중에는 갤러리와 '새 타이머' 칩이 없습니다.
/// 둘 다 없으면 작업·휴식을 고르고 다이얼을 끌거나 시계를 눌러 '시간 정하기'에서 각각의 시간을 초 단위로 고릅니다.
class TimerDashboardView extends StatefulWidget {
  const TimerDashboardView({
    super.key,
    required this.model,
    required this.onFocusTimer,
    required this.onTodoStatusSelected,
    required this.addTimerBuilder,
    required this.controlsBuilder,
    this.focusLeading,
    this.focusActions = const [],
  });

  final TimerDashboardModel model;

  /// 갤러리에서 보이는 쪽의 타이머 id
  final ValueChanged<String> onFocusTimer;

  /// 작업 제목 앞에서 고른 할 일 상태
  final ValueChanged<TodoStatus> onTodoStatusSelected;

  /// '새 타이머' 칩. [initialDuration]은 다이얼로 고른 집중 시간이고, [icon]이면 글자 없이 아이콘 버튼으로 둔다(집중 보기)
  final Widget Function(Duration initialDuration, bool icon) addTimerBuilder;

  /// 맨 아래 조작 버튼
  final TimerDashboardControlsBuilder controlsBuilder;

  /// 집중 보기에서 작업명 줄 왼쪽에 두는 것(화면 이동 ☰ 등). 집중 보기는 앱바 없이 이 줄이 맨 위다
  final Widget? focusLeading;

  /// 집중 보기에서 작업명 줄 오른쪽에 두는 버튼들
  final List<Widget> focusActions;

  @override
  State<TimerDashboardView> createState() => _TimerDashboardViewState();
}

class _TimerDashboardViewState extends State<TimerDashboardView> {
  /// 다이얼이나 '시간 정하기'로 고른 새 작업의 집중 시간 (초 단위)
  Duration _pendingDuration = defaultFocusDuration;

  /// 다이얼이나 '시간 정하기'로 고른 휴식 시간 (초 단위)
  Duration _pendingBreakDuration = defaultBreakDuration;

  /// 다이얼을 끄는 동안 손가락이 가리키는 시간. 끌지 않으면 null
  Duration? _dragPreview;

  /// 대기 상태에서 작업 대신 휴식을 골랐는지
  bool _breakSelected = false;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final activeTimer = model.activeTimer;
    final breakSession = model.breakSession;
    final pending = _breakSelected ? _pendingBreakDuration : _pendingDuration;
    final dialColor = model.dialColor(
      Theme.of(context).colorScheme,
      breakSelected: _breakSelected,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = TimerDashboardLayout.isShort(constraints);
        final focus = ShellScope.compactOf(context);
        final dial = _MainDial(
          labels: !focus,
          model: model,
          pending: pending,
          color: dialColor,
          label: _breakSelected ? '${Terms.rest} 시간' : '${Terms.focus} 시간',
          onPreview: (duration) => setState(() => _dragPreview = duration),
          onChanged: _setPending,
        );
        final clock = DigitalClock(
          duration: breakSession != null
              ? model.breakRemaining
              : activeTimer == null
              ? _dragPreview ?? pending
              : model.remaining,
          timeUp: model.timeUp,
          idle: model.idle,
          compact: short,
        );
        final gap = SizedBox(height: short ? 8 : 16);
        final caption = model.caption;
        return TimerDashboardLayout(
          constraints: constraints,
          dial: model.galleryShown
              ? _ActiveTimersGallery(
                  model: model,
                  focusedDial: dial,
                  labels: !focus,
                  onFocus: widget.onFocusTimer,
                )
              : dial,
          addTimer: model.onBreak || model.myTimers.isEmpty
              ? null
              : widget.addTimerBuilder(_pendingDuration, focus),
          header: _DashboardHeader(
            onBreak: model.onBreak,
            timer: activeTimer,
            onTodoStatusSelected: widget.onTodoStatusSelected,
          ),
          focus: focus,
          focusLeading: widget.focusLeading,
          focusActions: widget.focusActions,
          clock: model.idle
              ? _EditableClock(clock: clock, onTap: _pickPendingDuration)
              : clock,
          controls: [
            TimerDashboardActions(
              caption: caption,
              alert: model.timeUp,
              gap: gap,
              focus: focus,
              breakSelected: model.idle ? _breakSelected : null,
              onBreakSelected: (value) =>
                  setState(() => _breakSelected = value),
              controls: widget.controlsBuilder(
                breakSelected: _breakSelected,
                pendingDuration: _pendingDuration,
                pendingBreakDuration: _pendingBreakDuration,
              ),
            ),
          ],
        );
      },
    );
  }

  /// 고른 모드(작업·휴식)의 시간으로 둔다
  void _setPending(Duration duration) {
    setState(() {
      if (_breakSelected) {
        _pendingBreakDuration = duration;
      } else {
        _pendingDuration = duration;
      }
    });
  }

  /// '시간 정하기'에서 고른 시간을 고른 모드(작업·휴식)의 시간으로 둔다
  Future<void> _pickPendingDuration() async {
    final picked = await showDurationPickerSheet(
      context,
      initial: _breakSelected ? _pendingBreakDuration : _pendingDuration,
    );
    if (picked == null || !mounted) return;
    _setPending(picked);
  }
}

/// 활성 타이머마다 한 쪽씩 다이얼을 둔 갤러리. 보이는 쪽([focusedDial])의 타이머를 [onFocus]로 알린다
class _ActiveTimersGallery extends StatelessWidget {
  const _ActiveTimersGallery({
    required this.model,
    required this.focusedDial,
    required this.labels,
    required this.onFocus,
  });

  final TimerDashboardModel model;
  final Widget focusedDial;

  /// 다른 쪽 다이얼에도 눈금 숫자를 그릴지
  final bool labels;
  final ValueChanged<String> onFocus;

  /// 넓은 화면이나 웹·데스크톱이면 갤러리에 이전·다음 버튼을 둔다
  static bool _showArrows(BuildContext context) =>
      kIsWeb ||
      MediaQuery.sizeOf(context).width >= timerWideLayoutMinWidth ||
      switch (defaultTargetPlatform) {
        TargetPlatform.linux ||
        TargetPlatform.macOS ||
        TargetPlatform.windows => true,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusedId = model.activeTimer?.id;
    final now = model.pageNow;
    return TimerGallery(
      timers: galleryOrder(model.myTimers),
      focusedId: focusedId,
      arrows: _showArrows(context),
      onFocus: onFocus,
      pageBuilder: (timer) {
        if (timer.id == focusedId) return focusedDial;
        return TimerDial(
          remaining: displayRemaining(timer, now),
          face: dialFaceFor(Duration(seconds: timer.allocatedDuration)),
          labels: labels,
          color: TimerDashboardModel.timerColor(
            colorScheme,
            timer,
            timeUp: isTimeUp(timer, now),
          ),
        );
      },
    );
  }
}

/// 큰 다이얼. 휴식·활성 타이머는 남은 시간을 보이고, 대기 중이면 끌어서 [pending] 시간을 고른다
class _MainDial extends StatelessWidget {
  const _MainDial({
    required this.labels,
    required this.model,
    required this.pending,
    required this.color,
    required this.label,
    required this.onPreview,
    required this.onChanged,
  });

  final TimerDashboardModel model;
  final Duration pending;
  final Color color;

  /// 눈금 숫자를 그릴지
  final bool labels;

  /// 대기 중 다이얼을 스크린 리더가 읽는 이름
  final String label;
  final ValueChanged<Duration?> onPreview;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final breakSession = model.breakSession;
    final activeTimer = model.activeTimer;
    if (breakSession != null) {
      return TimerDial(
        remaining: model.breakRemaining,
        face: dialFaceFor(breakSession.total),
        color: color,
        labels: labels,
      );
    }
    if (activeTimer == null) {
      return TimerDial(
        remaining: pending,
        color: color,
        labels: labels,
        label: label,
        onPreview: onPreview,
        onChanged: onChanged,
      );
    }
    return TimerDial(
      remaining: model.remaining,
      face: dialFaceFor(Duration(seconds: activeTimer.allocatedDuration)),
      color: color,
      labels: labels,
    );
  }
}

/// 휴식 중이면 '휴식', 아니면 [timer]의 작업 제목
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onBreak,
    required this.timer,
    required this.onTodoStatusSelected,
  });

  final bool onBreak;
  final TimerRead? timer;
  final ValueChanged<TodoStatus> onTodoStatusSelected;

  @override
  Widget build(BuildContext context) {
    if (onBreak) {
      return Text(
        Terms.rest,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
      );
    }
    return CurrentTaskDisplay(
      timer: timer,
      onTodoStatusSelected: onTodoStatusSelected,
    );
  }
}

/// 누르면 '시간 정하기'를 여는 시계
class _EditableClock extends StatelessWidget {
  const _EditableClock({required this.clock, required this.onTap});

  final Widget clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '시간 정하기',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          // 좁은 오른쪽 칸(가로 휴대폰)에서는 연필 표시까지 함께 줄인다
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                clock,
                const SizedBox(width: 4),
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
