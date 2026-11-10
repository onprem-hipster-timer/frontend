import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
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

/// 이 폭보다 좁으면 다이얼만 두고 타이머 목록은 바텀 시트로 연다
const timerWideLayoutMinWidth = 600.0;

/// 다이얼 옆에 둘 때 작업 제목·시계·버튼 칸의 가장 좁은 폭. 일시정지 타이머의 버튼 세 개(216)가 들어간다
const _sideControlsMinWidth = 232.0;

/// 낮은 칸에서 다이얼을 옆에 둘 때 다이얼이 이보다 작아지면 위아래로 둔다
const _sideDialMinSide = 80.0;

/// 타이머 대시보드
///
/// 작업 제목, 다이얼, 디지털 시계, 상태 캡션, 제어 버튼을 위에서부터 둡니다. 다이얼이 남는 높이를 모두 씁니다.
/// 높이 400 미만이고 폭이 높이 이상이며 옆에 두어도 다이얼이 [_sideDialMinSide] 이상인 칸(가로 휴대폰)은
/// 다이얼을 왼쪽에 두고 제목부터 나머지를 오른쪽에 둡니다.
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
    final theme = Theme.of(context);
    final activeTimerAsync = ref.watch(activeTimerProvider);
    final timerTicker = ref.watch(timerTickerProvider);
    final controllerState = ref.watch(timerControllerProvider);
    final activeTimer = activeTimerAsync.when(
      data: (timer) => timer,
      loading: () => null,
      error: (error, stack) => null,
    );
    final now = ref.watch(serverClockProvider).now();
    final computed = activeTimer == null
        ? Duration.zero
        : displayRemaining(activeTimer, now);
    final remaining = timerTicker.when(
      data: (duration) => duration,
      loading: () => computed,
      error: (error, stack) => computed,
    );

    // 휴식은 활성 타이머보다 먼저 보인다
    final breakSession = ref.watch(breakTimerProvider);
    final breakComputed = breakSession?.remainingAt(now) ?? Duration.zero;
    final breakRemaining = ref
        .watch(breakTickerProvider)
        .when(
          data: (duration) => duration,
          loading: () => breakComputed,
          error: (error, stack) => breakComputed,
        );
    final breakOver = breakSession != null && breakRemaining == Duration.zero;
    final idle = breakSession == null && activeTimer == null;
    final pending = _breakSelected ? _pendingBreakDuration : _pendingDuration;
    final myTimers = ref.watch(myActiveTimersProvider).value ?? const [];
    // 보이는 타이머가 일시정지여도 시간이 남은 채 실행 중인 다른 내 타이머가 있으면 휴식 버튼을 두지 않는다
    final breakBlocked = blocksBreak(myTimers, now);
    final galleryShown = breakSession == null && myTimers.length >= 2;
    // 갤러리의 다른 쪽도 서버 기준 시각으로 1초마다 센다
    final pageNow = galleryShown
        ? ref.watch(serverNowProvider).value ?? now
        : now;

    final timeUp =
        breakSession == null &&
        activeTimer != null &&
        (remaining == Duration.zero || isTimeUp(activeTimer, now));
    Color timerColor(TimerRead timer, {required bool timeUp}) => timeUp
        ? theme.colorScheme.error
        : timer.status == TimerStatus.paused
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : theme.colorScheme.primary;
    final dialColor = breakSession != null || (idle && _breakSelected)
        ? theme.colorScheme.tertiary
        : activeTimer == null
        ? theme.colorScheme.primary
        : timerColor(activeTimer, timeUp: timeUp);

    final caption = breakSession != null
        ? (breakOver ? '휴식 종료' : null)
        : timeUp
        ? '시간 종료'
        : activeTimer?.status == TimerStatus.paused
        ? '일시정지'
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 400;
        final gap = SizedBox(height: short ? 8 : 16);

        final dial = breakSession != null
            ? TimerDial(
                remaining: breakRemaining,
                face: dialFaceFor(breakSession.total),
                color: dialColor,
              )
            : activeTimer == null
            ? TimerDial(
                remaining: pending,
                color: dialColor,
                label: _breakSelected ? '휴식 시간' : '집중 시간',
                onPreview: (duration) =>
                    setState(() => _dragPreview = duration),
                onChanged: (duration) => setState(() {
                  if (_breakSelected) {
                    _pendingBreakDuration = duration;
                  } else {
                    _pendingDuration = duration;
                  }
                }),
              )
            : TimerDial(
                remaining: remaining,
                face: dialFaceFor(
                  Duration(seconds: activeTimer.allocatedDuration),
                ),
                color: dialColor,
              );

        final gallery = galleryShown
            ? TimerGallery(
                timers: galleryOrder(myTimers),
                focusedId: activeTimer?.id,
                arrows: _showGalleryArrows(context),
                onFocus: (timerId) =>
                    ref.read(focusedTimerIdProvider.notifier).focus(timerId),
                pageBuilder: (timer) {
                  if (timer.id == activeTimer?.id) return dial;
                  return TimerDial(
                    remaining: displayRemaining(timer, pageNow),
                    face: dialFaceFor(
                      Duration(seconds: timer.allocatedDuration),
                    ),
                    color: timerColor(timer, timeUp: isTimeUp(timer, pageNow)),
                  );
                },
              )
            : null;

        final addTimer = breakSession == null && myTimers.isNotEmpty
            ? ActionChip(
                avatar: const Icon(Icons.add),
                label: const Text('새 타이머'),
                onPressed: controllerState.isLoading
                    ? null
                    : () => startTimerFromSheet(
                        context,
                        ref,
                        initialDuration: _pendingDuration,
                      ),
              )
            : null;

        final header = breakSession != null
            ? Text(
                '휴식',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              )
            : CurrentTaskDisplay(
                timer: activeTimer,
                onTodoChanged: (todo) {
                  if (!context.mounted) return;
                  ref.read(myActiveTimersProvider.notifier).updateTodo(todo);
                },
              );

        final clock = DigitalClock(
          duration: breakSession != null
              ? breakRemaining
              : activeTimer == null
              ? _dragPreview ?? pending
              : remaining,
          timeUp: timeUp,
          idle: idle,
          compact: short,
        );

        final controls = [
          if (idle)
            Tooltip(
              message: '시간 정하기',
              child: InkWell(
                onTap: _pickPendingDuration,
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
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            clock,
          if (caption != null)
            Text(
              caption,
              style: theme.textTheme.labelMedium?.copyWith(
                color: timeUp
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          gap,
          if (idle) ...[
            SegmentedButton<bool>(
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
              selected: {_breakSelected},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _breakSelected = selection.single),
            ),
            gap,
          ],
          TimerDashboardControls(
            onBreak: breakSession != null,
            breakOver: breakOver,
            activeTimer: activeTimer,
            timeUp: timeUp,
            breakSelected: _breakSelected,
            breakBlocked: breakBlocked,
            pendingDuration: _pendingDuration,
            pendingBreakDuration: _pendingBreakDuration,
          ),
        ];

        // 낮고 넓은 칸(가로 휴대폰)은 다이얼 오른쪽에 나머지를 두고, 나머지가 칸보다 길면 굴린다
        final sideDialWidth =
            constraints.maxWidth - 24 * 2 - 16 - _sideControlsMinWidth;
        if (short &&
            constraints.maxWidth >= constraints.maxHeight &&
            sideDialWidth >= _sideDialMinSide) {
          return _SideBySideDashboard(
            dial: gallery ?? dial,
            addTimer: addTimer,
            children: [header, gap, ...controls],
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: short ? 8 : 16,
          ),
          child: Column(
            children: [
              if (addTimer != null) ...[
                Align(alignment: Alignment.centerRight, child: addTimer),
                gap,
              ],
              header,
              gap,
              Expanded(child: gallery ?? dial),
              gap,
              ...controls,
            ],
          ),
        );
      },
    );
  }

  /// '시간 정하기'에서 고른 시간을 고른 모드(작업·휴식)의 시간으로 둔다
  Future<void> _pickPendingDuration() async {
    final picked = await showDurationPickerSheet(
      context,
      initial: _breakSelected ? _pendingBreakDuration : _pendingDuration,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (_breakSelected) {
        _pendingBreakDuration = picked;
      } else {
        _pendingDuration = picked;
      }
    });
  }

  /// 넓은 화면이나 웹·데스크톱이면 갤러리에 이전·다음 버튼을 둔다
  static bool _showGalleryArrows(BuildContext context) =>
      kIsWeb ||
      MediaQuery.sizeOf(context).width >= timerWideLayoutMinWidth ||
      switch (defaultTargetPlatform) {
        TargetPlatform.linux ||
        TargetPlatform.macOS ||
        TargetPlatform.windows => true,
        _ => false,
      };
}

/// 낮고 넓은 칸의 대시보드. 다이얼을 왼쪽에, [addTimer]와 [children]을 오른쪽에 두고 오른쪽이 길면 굴린다
class _SideBySideDashboard extends StatelessWidget {
  const _SideBySideDashboard({
    required this.dial,
    required this.addTimer,
    required this.children,
  });

  final Widget dial;
  final Widget? addTimer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final addTimer = this.addTimer;
    return LayoutBuilder(
      builder: (context, constraints) {
        final controlsWidth = math.max(
          _sideControlsMinWidth,
          (constraints.maxWidth - 24 * 2 - 16) / 2,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Expanded(child: dial),
              const SizedBox(width: 16),
              SizedBox(
                width: controlsWidth,
                child: Column(
                  children: [
                    if (addTimer != null)
                      Align(alignment: Alignment.centerRight, child: addTimer),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: children,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
