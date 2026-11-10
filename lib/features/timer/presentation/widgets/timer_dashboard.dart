import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/duration_picker_sheet.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/features/timer/presentation/utils/timer_actions.dart';
import 'package:momeet/features/timer/presentation/widgets/current_task_display.dart';
import 'package:momeet/features/timer/presentation/widgets/digital_clock.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_gallery.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_controls.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_layout.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dashboard_model.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart' show ShellScope;

/// 이 폭보다 좁으면 다이얼만 두고 타이머 목록은 바텀 시트로 연다
const timerWideLayoutMinWidth = 600.0;

/// 타이머 대시보드
///
/// 작업 제목, 다이얼, 디지털 시계, 상태 캡션, 제어 버튼을 위에서부터 둡니다. 다이얼이 남는 높이를 모두 씁니다.
/// 낮고 넓은 칸(가로 휴대폰)은 다이얼을 왼쪽에 두고 제목부터 나머지를 오른쪽에 둡니다([TimerDashboardLayout]).
/// 휴식 중이면 휴식을, 아니면 고른 활성 타이머([activeTimerProvider])를 보여 주고, 다이얼은 남은 시간만 보여 줍니다.
/// 활성 타이머가 둘 이상이면 다이얼 자리에 타이머마다 한 쪽씩 다이얼을 둔 갤러리([TimerGallery])를 두고,
/// 보이는 쪽의 타이머를 고릅니다. 활성 타이머가 있으면 굴리지 않는 '새 타이머' 칩으로 다른 타이머가 도는 중에도
/// 새 작업을 시작합니다. 휴식 중에는 갤러리와 '새 타이머' 칩이 없습니다.
/// 둘 다 없으면 작업·휴식을 고르고 다이얼을 끌거나 시계를 눌러 '시간 정하기'에서 각각의 시간을 초 단위로 고릅니다.
/// 휴식은 서버에 보내지 않고 바로 시작합니다.
class TimerDashboard extends ConsumerStatefulWidget {
  const TimerDashboard({super.key});

  @override
  ConsumerState<TimerDashboard> createState() => _TimerDashboardState();
}

class _TimerDashboardState extends ConsumerState<TimerDashboard> {
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
    final model = TimerDashboardModel.watch(ref);
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
        final dial = _MainDial(
          model: model,
          pending: pending,
          color: dialColor,
          label: _breakSelected ? '휴식 시간' : '집중 시간',
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
        final focus = ShellScope.compactOf(context);

        return TimerDashboardLayout(
          constraints: constraints,
          dial: model.galleryShown
              ? _ActiveTimersGallery(model: model, focusedDial: dial)
              : dial,
          addTimer: model.onBreak || model.myTimers.isEmpty
              ? null
              : _AddTimerChip(initialDuration: _pendingDuration, icon: focus),
          header: _DashboardHeader(onBreak: model.onBreak, timer: activeTimer),
          focus: focus,
          clock: model.idle
              ? _EditableClock(clock: clock, onTap: _pickPendingDuration)
              : clock,
          controls: [
            if (caption != null) _Caption(caption, alert: model.timeUp),
            gap,
            if (model.idle) ...[
              _ModeToggle(
                breakSelected: _breakSelected,
                onChanged: (value) => setState(() => _breakSelected = value),
              ),
              gap,
            ],
            TimerDashboardControls(
              onBreak: model.onBreak,
              breakOver: model.breakOver,
              activeTimer: activeTimer,
              timeUp: model.timeUp,
              breakSelected: _breakSelected,
              breakBlocked: model.breakBlocked,
              pendingDuration: _pendingDuration,
              pendingBreakDuration: _pendingBreakDuration,
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

/// 활성 타이머마다 한 쪽씩 다이얼을 둔 갤러리. 보이는 쪽([focusedDial])의 타이머를 고른다
class _ActiveTimersGallery extends ConsumerWidget {
  const _ActiveTimersGallery({required this.model, required this.focusedDial});

  final TimerDashboardModel model;
  final Widget focusedDial;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusedId = model.activeTimer?.id;
    final now = model.pageNow;
    return TimerGallery(
      timers: galleryOrder(model.myTimers),
      focusedId: focusedId,
      arrows: _showArrows(context),
      onFocus: (timerId) =>
          ref.read(focusedTimerIdProvider.notifier).focus(timerId),
      pageBuilder: (timer) {
        if (timer.id == focusedId) return focusedDial;
        return TimerDial(
          remaining: displayRemaining(timer, now),
          face: dialFaceFor(Duration(seconds: timer.allocatedDuration)),
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
      );
    }
    if (activeTimer == null) {
      return TimerDial(
        remaining: pending,
        color: color,
        label: label,
        onPreview: onPreview,
        onChanged: onChanged,
      );
    }
    return TimerDial(
      remaining: model.remaining,
      face: dialFaceFor(Duration(seconds: activeTimer.allocatedDuration)),
      color: color,
    );
  }
}

/// 다른 타이머가 도는 중에도 새 작업을 시작하는 칩
class _AddTimerChip extends ConsumerWidget {
  const _AddTimerChip({required this.initialDuration, this.icon = false});

  final Duration initialDuration;

  /// 글자 없이 아이콘 버튼으로 둔다(집중 보기)
  final bool icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPressed = ref.watch(timerControllerProvider).isLoading
        ? null
        : () => startTimerFromSheet(
            context,
            ref,
            initialDuration: initialDuration,
          );
    if (icon) {
      return IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: '새 타이머',
        onPressed: onPressed,
      );
    }
    return ActionChip(
      avatar: const Icon(Icons.add),
      label: const Text('새 타이머'),
      onPressed: onPressed,
    );
  }
}

/// 휴식 중이면 '휴식', 아니면 [timer]의 작업 제목
class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({required this.onBreak, required this.timer});

  final bool onBreak;
  final TimerRead? timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (onBreak) {
      return Text(
        '휴식',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
      );
    }
    return CurrentTaskDisplay(
      timer: timer,
      onTodoChanged: (todo) {
        if (!context.mounted) return;
        ref.read(myActiveTimersProvider.notifier).updateTodo(todo);
      },
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

/// 다이얼 아래 상태 문구. [alert]면 오류색
class _Caption extends StatelessWidget {
  const _Caption(this.text, {required this.alert});

  final String text;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: alert
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 대기 중 작업·휴식 고르기
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.breakSelected, required this.onChanged});

  final bool breakSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          label: Text('작업'),
          icon: Icon(Icons.timer_outlined),
        ),
        ButtonSegment(
          value: true,
          label: Text('휴식'),
          icon: Icon(Icons.coffee_outlined),
        ),
      ],
      selected: {breakSelected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
