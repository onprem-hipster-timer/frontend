import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/break_timer_provider.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_dialog.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_share_sheet.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/providers/friend_providers.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

/// 이 폭보다 좁으면 다이얼만 두고 타이머 목록은 바텀 시트로 연다
const _wideLayoutMinWidth = 600.0;

/// 타이머 대시보드 페이지
///
/// 실시간 타이머 표시, 제어 버튼, 히스토리 목록을 제공합니다.
/// 넓은 화면은 다이얼 옆에 타이머 목록을 두고, 좁은 화면은 다이얼만 두고 앱 바에서 목록을 엽니다.
class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  /// 레이아웃이 바뀌어도 대시보드 상태(다이얼로 고른 시간)를 옮겨 쓴다
  final _dashboardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final dashboard = TimerDashboard(key: _dashboardKey);

    final lastError = ref.watch(timerWsLastErrorProvider);

    ref.listen<AsyncValue<TimerWsTimerEvent>>(timerFriendActivityProvider, (
      _,
      next,
    ) {
      next.whenData((event) {
        // 시간 종료(expire)는 함께 오는 명령(정지 등)의 알림과 겹치므로 띄우지 않는다
        if (event.payload.action == 'expire' || !context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendActivityMessage(event))));
      });
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideLayoutMinWidth;

        return Scaffold(
          appBar: AppBar(
            title: const Text('타이머'),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              if (!wide)
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: '타이머 목록',
                  onPressed: () => _showHistorySheet(context),
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ErrorBanner(
                  message: lastError?.message,
                  onDismiss: () => ref
                      .read(timerWsLastErrorProvider.notifier)
                      .setError(null),
                ),
              ),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: dashboard),
                          const VerticalDivider(width: 1),
                          const Expanded(flex: 2, child: TimerHistoryList()),
                        ],
                      )
                    : dashboard,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, scrollController) =>
            TimerHistoryList(scrollController: scrollController),
      ),
    );
  }
}

/// 친구의 타이머 이벤트를 SnackBar 문구로 변환한다.
///
/// `payload.action` 중 start/pause/resume/stop만 매핑하고,
/// 그 외 action은 generic fallback 문구로 처리한다.
/// `payload.actor_name`이 없거나 빈 문자열이면 `친구`로 대체한다.
String friendActivityMessage(TimerWsTimerEvent event) {
  final actorName = event.payload.actorName?.trim();
  final friendName = actorName == null || actorName.isEmpty ? '친구' : actorName;
  final timerTitle = event.payload.timer?.title?.trim();
  final target = timerTitle == null || timerTitle.isEmpty
      ? '타이머'
      : '$timerTitle 타이머';

  return switch (event.payload.action) {
    'start' => '$friendName님이 $target를 시작했습니다',
    'pause' => '$friendName님이 $target를 일시정지했습니다',
    'resume' => '$friendName님이 $target를 재개했습니다',
    'stop' => '$friendName님이 $target를 정지했습니다',
    _ => '$friendName님의 타이머 상태가 변경되었습니다',
  };
}

const _stopTimerConfirmTitle = '작업 완료';
const _stopTimerConfirmContent =
    '작업을 완료하시겠습니까?\n완료한 타이머는 다시 시작할 수 없습니다.\n잠시 멈추려면 일시정지를 이용해 주세요.';

/// 타이머 완료 확인 다이얼로그. 사용자가 완료를 확인하면 true.
Future<bool> _confirmStopTimer(BuildContext context) {
  return showConfirmDialog(
    context,
    title: _stopTimerConfirmTitle,
    content: _stopTimerConfirmContent,
    confirmText: '완료',
    destructive: true,
  );
}

/// 시간이 끝난 타이머를 한 번에 늘리는 시간
const _extendBy = Duration(minutes: 5);

/// 다이얼 옆에 둘 때 작업 제목·시계·버튼 칸의 가장 좁은 폭. 일시정지 타이머의 버튼 세 개(216)가 들어간다
const _sideControlsMinWidth = 232.0;

/// 타이머 대시보드
///
/// 다이얼, 작업 제목, 디지털 시계, 상태 캡션, 제어 버튼을 위에서부터 둡니다. 다이얼이 남는 높이를 모두 씁니다.
/// 높이 400 미만에 폭이 높이의 1.5배 이상인 칸(가로 휴대폰)은 다이얼을 왼쪽에 두고 나머지를 오른쪽에 둡니다.
/// 휴식 중이면 휴식을, 아니면 활성 타이머를 보여 주고, 다이얼은 남은 시간만 보여 줍니다.
/// 둘 다 없으면 작업·휴식을 고르고 다이얼을 끌어 각각의 시간을 고릅니다. 휴식은 서버에 보내지 않고 바로 시작합니다.
class TimerDashboard extends ConsumerStatefulWidget {
  const TimerDashboard({super.key});

  @override
  ConsumerState<TimerDashboard> createState() => _TimerDashboardState();
}

class _TimerDashboardState extends ConsumerState<TimerDashboard> {
  /// 다이얼로 고른 새 작업의 집중 시간
  Duration _pendingDuration = defaultFocusDuration;

  /// 다이얼로 고른 휴식 시간
  Duration _pendingBreakDuration = defaultBreakDuration;

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
    final breakComputed =
        breakSession?.remainingAt(ref.watch(breakClockProvider)()) ??
        Duration.zero;
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
    // 보이는 타이머가 일시정지여도 시간이 남은 채 실행 중인 다른 내 타이머가 있으면 휴식 버튼을 두지 않는다
    final breakBlocked = blocksBreak(
      ref.watch(myActiveTimersProvider).value ?? const [],
      now,
    );

    final timeUp =
        breakSession == null &&
        activeTimer != null &&
        (remaining == Duration.zero || isTimeUp(activeTimer, now));
    final dialColor = breakSession != null || (idle && _breakSelected)
        ? theme.colorScheme.tertiary
        : timeUp
        ? theme.colorScheme.error
        : activeTimer?.status == TimerStatus.paused
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : theme.colorScheme.primary;

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

        final controls = [
          if (breakSession != null)
            Text(
              '휴식',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            )
          else
            CurrentTaskDisplay(
              timer: activeTimer,
              onTodoChanged: (todo) {
                if (!context.mounted) return;
                ref.read(myActiveTimersProvider.notifier).updateTodo(todo);
              },
            ),
          DigitalClock(
            duration: breakSession != null
                ? breakRemaining
                : activeTimer == null
                ? pending
                : remaining,
            timeUp: timeUp,
            idle: idle,
            compact: short,
          ),
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
          if (breakSession != null)
            FloatingActionButton(
              onPressed: () => ref.read(breakTimerProvider.notifier).end(),
              tooltip: breakOver ? '확인' : '휴식 끝내기',
              backgroundColor: theme.colorScheme.tertiary,
              child: Icon(
                breakOver ? Icons.check : Icons.stop,
                color: theme.colorScheme.onTertiary,
              ),
            )
          else
            TimerControlButton(
              activeTimer: activeTimer,
              starting: controllerState.isLoading,
              timeUp: timeUp,
              breakSelected: _breakSelected,
              onStart: () => _showStartTimerDialog(context, ref),
              onStartBreak: breakBlocked
                  ? null
                  : () => ref
                        .read(breakTimerProvider.notifier)
                        .start(_pendingBreakDuration),
              onStop: () => _stopTimer(context, ref),
              onPause: () => _pauseTimer(context, ref),
              onResume: () => _resumeTimer(context, ref),
              onExtend: () => _extendTimer(context, ref),
            ),
        ];

        // 낮고 넓은 칸(가로 휴대폰)은 다이얼 오른쪽에 나머지를 두고, 나머지가 칸보다 길면 굴린다
        if (short && constraints.maxWidth >= constraints.maxHeight * 1.5) {
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
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: controls,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: short ? 8 : 16,
          ),
          child: Column(
            children: [
              Expanded(child: dial),
              gap,
              ...controls,
            ],
          ),
        );
      },
    );
  }

  /// 새 작업 시작 다이얼로그를 열고 고른 값으로 타이머를 시작한다
  void _showStartTimerDialog(BuildContext context, WidgetRef ref) async {
    final input = await showStartTimerDialog(
      context,
      initialDuration: _pendingDuration,
    );
    if (input == null || !context.mounted) return;
    try {
      await ref
          .read(timerControllerProvider.notifier)
          .startTimer(
            relatedTodoId: input.todo?.id,
            title: input.title,
            allocatedDurationSeconds: input.duration.inSeconds,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('타이머를 시작했습니다')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('타이머 시작 실패: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 타이머 완료 (정지)
  void _stopTimer(BuildContext context, WidgetRef ref) async {
    final activeTimer = ref
        .read(activeTimerProvider)
        .when(
          data: (timer) => timer,
          loading: () => null,
          error: (_, _) => null,
        );

    if (activeTimer == null || activeTimer.status == TimerStatus.completed) {
      ref.invalidate(myActiveTimersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('진행 중인 작업이 없습니다.')));
      }
      return;
    }

    final confirmed = await _confirmStopTimer(context);
    if (!context.mounted || !confirmed) return;

    try {
      // 확인 시점에 캡처한 타이머 id로 정지 — 다이얼로그가 열린 사이
      // 활성 타이머가 바뀌어도 사용자가 확인한 타이머만 정지한다.
      await ref
          .read(timerControllerProvider.notifier)
          .stopTimer(timerId: activeTimer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('작업을 완료했습니다'),
            action: SnackBarAction(
              label: '새 타이머 시작',
              onPressed: () {
                if (!context.mounted) return;
                _showStartTimerDialog(context, ref);
              },
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('완료 실패: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 타이머 일시정지
  void _pauseTimer(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(timerControllerProvider.notifier).pauseTimer();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('일시정지 실패: ${error.toString()}')));
      }
    }
  }

  /// 타이머 재개
  void _resumeTimer(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(timerControllerProvider.notifier).resumeTimer();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('재개 실패: ${error.toString()}')));
      }
    }
  }

  /// 타이머 5분 연장
  void _extendTimer(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(timerControllerProvider.notifier)
          .extendTimer(by: _extendBy);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('연장 실패: ${error.toString()}')));
      }
    }
  }
}

/// 디지털 시계 위젯
///
/// HH:MM:SS 형식으로 남은 시간을 표시합니다. 집중 시간이 끝나면([timeUp]) 에러 색,
/// 활성 타이머 없이 고른 시간이면([idle]) 흐린 색으로 표시합니다.
class DigitalClock extends StatelessWidget {
  final Duration duration;
  final bool timeUp;
  final bool idle;
  final bool compact;

  const DigitalClock({
    super.key,
    required this.duration,
    this.timeUp = false,
    this.idle = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = formatDuration(duration);

    return Text(
      timeText,
      style: theme.textTheme.displayLarge?.copyWith(
        fontFamily: 'monospace', // 등폭 폰트 사용
        fontSize: compact ? 24 : 28,
        fontWeight: FontWeight.w400,
        color: timeUp
            ? theme.colorScheme.error
            : !idle
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 2,
      ),
    );
  }
}

/// 현재 작업 표시 위젯
///
/// 연결된 Todo가 있으면 제목 옆에 Todo 상태를 표시하고, 일시정지 중에는 그 자리에서 바꿀 수 있습니다.
/// 바꾼 뒤 서버가 돌려준 Todo로 [onTodoChanged]를 부릅니다.
/// 내 타이머면 제목 뒤에 공유 범위 버튼([TimerShareButton])을 둡니다.
class CurrentTaskDisplay extends StatelessWidget {
  final TimerRead? timer;
  final ValueChanged<TodoRead>? onTodoChanged;

  const CurrentTaskDisplay({
    super.key,
    required this.timer,
    this.onTodoChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (timer == null) {
      return Text(
        '진행 중인 작업이 없습니다',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    final taskName =
        timer!.title ??
        timer!.todo?.title ??
        timer!.schedule?.title ??
        '알 수 없는 작업';
    final todo = timer!.todo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (todo != null) ...[
          if (timer!.status == TimerStatus.paused)
            TodoStatusSelector(todo: todo, onChanged: onTodoChanged)
          else
            Icon(
              todo.status.icon,
              color: todo.status.color(context),
              semanticLabel: todo.status.label,
            ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            taskName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!timer!.isShared) TimerShareButton(timer: timer!),
      ],
    );
  }
}

/// 타이머 제어 버튼
///
/// 일시정지·재개는 누르는 즉시 [activeTimer]에 반영되므로 버튼을 그대로 둔다.
/// 새 타이머 시작만 응답을 기다리고([starting]), 그동안 시작 버튼 안에 진행 표시를 둔다.
/// 집중 시간이 끝나면([timeUp]) 일시정지·재개 대신 연장([onExtend]) 버튼을 둔다.
/// 활성 타이머 없이 휴식을 골랐으면([breakSelected]) 시작 버튼이 휴식을 바로 시작하고([onStartBreak]),
/// 시간이 남은 일시정지 타이머에는 휴식 버튼을 더 둔다. 휴식을 시작할 수 없으면 [onStartBreak]이 null이고 휴식 버튼이 없다.
class TimerControlButton extends StatelessWidget {
  final TimerRead? activeTimer;
  final bool starting;
  final bool timeUp;
  final bool breakSelected;
  final VoidCallback onStart;
  final VoidCallback? onStartBreak;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onExtend;

  const TimerControlButton({
    super.key,
    required this.activeTimer,
    required this.starting,
    required this.timeUp,
    required this.breakSelected,
    required this.onStart,
    required this.onStartBreak,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeTimer == null && breakSelected) {
      return FloatingActionButton(
        onPressed: onStartBreak,
        tooltip: '휴식 시작',
        backgroundColor: theme.colorScheme.tertiary,
        child: Icon(
          Icons.coffee,
          size: 32,
          color: theme.colorScheme.onTertiary,
        ),
      );
    } else if (activeTimer == null) {
      return FloatingActionButton(
        onPressed: starting ? null : onStart,
        backgroundColor: theme.colorScheme.primary,
        child: starting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Icon(
                Icons.play_arrow,
                size: 32,
                color: theme.colorScheme.onPrimary,
              ),
      );
    } else if (timeUp) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.small(
            onPressed: onStop,
            tooltip: '완료',
            backgroundColor: theme.colorScheme.error,
            child: Icon(Icons.check, color: theme.colorScheme.onError),
          ),
          const SizedBox(width: 40),
          FloatingActionButton(
            onPressed: onExtend,
            tooltip: '5분 연장',
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
          ),
        ],
      );
    } else if (activeTimer!.status == TimerStatus.running) {
      // 위계: 자주 쓰는 일시정지를 큰 주 버튼(primary), 비가역 완료는
      // 작은 보조 버튼(error)으로 + 간격을 넓혀 오탭을 방지한다.
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.small(
            onPressed: onStop,
            tooltip: '완료',
            backgroundColor: theme.colorScheme.error,
            child: Icon(Icons.check, color: theme.colorScheme.onError),
          ),
          const SizedBox(width: 40),
          FloatingActionButton(
            onPressed: onPause,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.pause, color: theme.colorScheme.onPrimary),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.small(
            onPressed: onStop,
            tooltip: '완료',
            backgroundColor: theme.colorScheme.error,
            child: Icon(Icons.check, color: theme.colorScheme.onError),
          ),
          const SizedBox(width: 40),
          FloatingActionButton(
            onPressed: onResume,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(Icons.play_arrow, color: theme.colorScheme.onPrimary),
          ),
          if (onStartBreak != null) ...[
            const SizedBox(width: 40),
            FloatingActionButton.small(
              onPressed: onStartBreak,
              tooltip: '휴식',
              backgroundColor: theme.colorScheme.tertiary,
              child: Icon(Icons.coffee, color: theme.colorScheme.onTertiary),
            ),
          ],
        ],
      );
    }
  }
}

/// 타이머 히스토리 목록
///
/// 머리말 아래에서 내 타이머와 친구가 공유한 타이머를 골라 봅니다. 친구 타이머를 고를 때마다 다시 읽습니다.
/// 바텀 시트 안에서는 시트의 [scrollController]로 목록을 스크롤합니다.
class TimerHistoryList extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const TimerHistoryList({super.key, this.scrollController});

  @override
  ConsumerState<TimerHistoryList> createState() => _TimerHistoryListState();
}

class _TimerHistoryListState extends ConsumerState<TimerHistoryList> {
  /// 친구가 공유한 타이머를 보는 중
  bool _shared = false;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(timerHistoryProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '타이머 목록',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('내 타이머')),
                ButtonSegment(value: true, label: Text('친구 타이머')),
              ],
              selected: {_shared},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _shared = selection.single);
                if (_shared) ref.invalidate(sharedTimersProvider);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _shared
                ? _SharedTimerList(scrollController: widget.scrollController)
                : historyAsync.when(
                    data: (timers) => timers.isEmpty
                        ? _buildEmptyState(context)
                        : _buildHistoryList(context, timers),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => _buildErrorState(context, error),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // 안내가 칸보다 길면 굴려 본다
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('타이머가 없습니다', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              '새 작업을 시작해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '히스토리를 불러올 수 없습니다',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, List<TimerRead> timers) {
    // 날짜별로 그룹화
    final groupedTimers = <String, List<TimerRead>>{};
    for (final timer in timers) {
      final date = formatDate(timer.startedAt ?? timer.createdAt);
      groupedTimers.putIfAbsent(date, () => []).add(timer);
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: groupedTimers.length,
      itemBuilder: (context, index) {
        final date = groupedTimers.keys.elementAt(index);
        final dateTimers = groupedTimers[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                date,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // 해당 날짜의 타이머들
            ...dateTimers.map((timer) => TimerHistoryItem(timer: timer)),
          ],
        );
      },
    );
  }
}

/// 친구가 공유한 타이머 목록. 주인 이름은 친구 목록에서 찾는다
class _SharedTimerList extends ConsumerWidget {
  const _SharedTimerList({this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 친구 목록을 읽지 못하면 이름 대신 '다른 사용자'로 보인다
    final friends = {
      for (final friend in ref.watch(friendsProvider).value ?? <FriendRead>[])
        friend.userId: friend,
    };

    return ref
        .watch(sharedTimersProvider)
        .when(
          // 안내가 칸보다 길면 굴려 본다
          data: (timers) => timers.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '공유받은 타이머가 없습니다',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: timers.length,
                  itemBuilder: (context, index) {
                    final timer = timers[index];
                    final owner = friends[timer.ownerId];
                    return SharedTimerItem(
                      timer: timer,
                      ownerName: owner == null
                          ? '다른 사용자'
                          : owner.displayName ?? '이름 없는 친구',
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          // 오류 문구가 칸보다 길면 굴려 본다
          error: (error, stack) => Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '공유받은 타이머를 불러올 수 없습니다',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
  }
}

/// 타이머 상태별 아이콘, 색, 이름
({IconData icon, Color bg, Color fg, String label}) _timerStatusStyle(
  BuildContext context,
  TimerStatus status,
) {
  final cs = Theme.of(context).colorScheme;
  switch (status) {
    case TimerStatus.running:
      return (
        icon: Icons.play_arrow,
        bg: Colors.green.shade100,
        fg: Colors.green.shade800,
        label: '진행 중',
      );
    case TimerStatus.paused:
      return (
        icon: Icons.pause,
        bg: Colors.orange.shade100,
        fg: Colors.orange.shade800,
        label: '일시정지',
      );
    case TimerStatus.cancelled:
      return (
        icon: Icons.cancel_outlined,
        bg: cs.surfaceContainerHighest,
        fg: cs.onSurfaceVariant,
        label: '취소',
      );
    default:
      return (
        icon: Icons.check_circle_outline,
        bg: cs.primaryContainer,
        fg: cs.onPrimaryContainer,
        label: '완료',
      );
  }
}

/// 타이머 상태 칩
class _TimerStatusChip extends StatelessWidget {
  const _TimerStatusChip(this.style);

  final ({IconData icon, Color bg, Color fg, String label}) style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        style.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: style.fg,
        ),
      ),
    );
  }
}

/// 타이머 목록 항목에서 버튼 말고 한 줄에 필요한 폭 (여백, 상태 아이콘, 제목, 남은 시간)
const _historyItemBaseWidth = 280.0;

/// 타이머 목록 항목의 버튼 하나의 폭 (탭 영역 48)
const _historyItemButtonWidth = 48.0;

/// 타이머 히스토리 항목
///
/// RUNNING/PAUSED일 때 실시간 남은 시간을, 끝난 타이머는 경과 시간을 표시하고, 일시정지·재개·완료 버튼을 제공합니다.
/// 집중 시간이 끝난 타이머는 일시정지·재개 대신 연장 버튼을 둡니다. 내 타이머는 맨 뒤에 공유 범위 버튼을 둡니다.
/// 버튼까지 한 줄에 두면 제목 자리가 모자란 폭이면 버튼을 아래 줄로 내립니다.
class TimerHistoryItem extends ConsumerWidget {
  final TimerRead timer;

  const TimerHistoryItem({super.key, required this.timer});

  /// 타이머 액션을 실행하고, 실패 시(예: WS 미연결) SnackBar로 피드백한다.
  ///
  /// 대시보드(`_pauseTimer` 등)·`TimerControlButtons`와 동일하게
  /// 히스토리 리스트의 액션에서도 예외가 사용자에게 전달되도록 한다.
  Future<void> _runTimerAction(
    BuildContext context,
    WidgetRef ref, {
    required Future<void> Function() action,
    required String errorLabel,
  }) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorLabel 실패: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 명령 응답 전 값이나 받은 응답을 목록을 다시 읽기 전에 먼저 보인다
    final timer = timerView(ref.watch(timerViewsProvider), this.timer);
    final style = _timerStatusStyle(context, timer.status);
    final activeTimer = ref
        .watch(activeTimerProvider)
        .when(data: (t) => t, loading: () => null, error: (_, _) => null);
    final tickerAsync = ref.watch(timerTickerProvider);

    final taskName =
        timer.title ??
        timer.todo?.title ??
        timer.schedule?.title ??
        '알 수 없는 작업';

    final startTime = timer.startedAt != null
        ? formatTime(timer.startedAt!)
        : '--:--';
    final endTime = timer.endedAt != null
        ? formatTime(timer.endedAt!)
        : '--:--';

    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;

    final bool useLiveTicker =
        timer.status == TimerStatus.running && timer.id == activeTimer?.id;
    final now = ref.watch(serverClockProvider).now();
    final timeUp = isTimeUp(timer, now);
    final shown = isActive
        ? displayRemaining(timer, now)
        : displayElapsed(timer, now);
    final Duration duration = useLiveTicker
        ? tickerAsync.when(
            data: (d) => d,
            loading: () => shown,
            error: (_, _) => shown,
          )
        : shown;

    final buttons = [
      if (isActive) ...[
        if (timeUp)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _runTimerAction(
              context,
              ref,
              action: () => ref
                  .read(timerControllerProvider.notifier)
                  .extendTimer(timerId: timer.id, by: _extendBy),
              errorLabel: '연장',
            ),
            tooltip: '5분 연장',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          )
        else if (timer.status == TimerStatus.running)
          IconButton(
            icon: const Icon(Icons.pause),
            onPressed: () => _runTimerAction(
              context,
              ref,
              action: () => ref
                  .read(timerControllerProvider.notifier)
                  .pauseTimer(timerId: timer.id),
              errorLabel: '일시정지',
            ),
            tooltip: '일시정지',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
            ),
          )
        else if (timer.status == TimerStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () => _runTimerAction(
              context,
              ref,
              action: () => ref
                  .read(timerControllerProvider.notifier)
                  .resumeTimer(timerId: timer.id),
              errorLabel: '재개',
            ),
            tooltip: '재개',
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
          ),
        IconButton(
          icon: Icon(Icons.check, color: theme.colorScheme.error),
          onPressed: () async {
            final confirmed = await _confirmStopTimer(context);
            if (!context.mounted || !confirmed) return;
            await _runTimerAction(
              context,
              ref,
              action: () => ref
                  .read(timerControllerProvider.notifier)
                  .stopTimer(timerId: timer.id),
              errorLabel: '완료',
            );
          },
          tooltip: '완료',
        ),
      ],
      if (!timer.isShared) TimerShareButton(timer: timer),
    ];
    final durationText = Text(
      formatDuration(duration),
      style: theme.textTheme.titleSmall?.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        color: isActive ? style.fg : theme.colorScheme.primary,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 좁으면 버튼을 아래 줄로 내려 제목 자리를 남긴다
          final stacked =
              buttons.isNotEmpty &&
              constraints.maxWidth <
                  _historyItemBaseWidth +
                      _historyItemButtonWidth * buttons.length;
          final tile = ListTile(
            leading: CircleAvatar(
              backgroundColor: style.bg,
              child: Icon(style.icon, color: style.fg),
            ),
            title: Text(
              taskName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Row(
              children: [
                if (isActive) ...[
                  Flexible(child: _TimerStatusChip(style)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    '$startTime - $endTime',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: stacked
                ? durationText
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      durationText,
                      if (isActive) const SizedBox(width: 4),
                      ...buttons,
                    ],
                  ),
          );
          if (!stacked) return tile;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: buttons,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 친구가 공유한 타이머 항목. 보기만 하고 버튼을 두지 않습니다
///
/// 작업 제목, 상태, 주인 이름([ownerName])을 보이고, RUNNING/PAUSED면 남은 시간을, 끝난 타이머는 경과 시간을 보입니다.
/// 실행 중이면 서버 기준 시각으로 1초마다 다시 셉니다.
class SharedTimerItem extends ConsumerWidget {
  const SharedTimerItem({
    super.key,
    required this.timer,
    required this.ownerName,
  });

  final TimerRead timer;
  final String ownerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = _timerStatusStyle(context, timer.status);
    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;
    final ticked = timer.status == TimerStatus.running
        ? ref.watch(serverNowProvider).value
        : null;
    final now = ticked ?? ref.watch(serverClockProvider).now();
    final duration = isActive
        ? displayRemaining(timer, now)
        : displayElapsed(timer, now);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: style.bg,
          child: Icon(style.icon, color: style.fg),
        ),
        title: Text(
          timer.title ?? timer.todo?.title ?? '알 수 없는 작업',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        // 이름이 한 줄에 안 들어가면 상태 아래 줄로 내린다
        subtitle: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TimerStatusChip(style),
            Text(ownerName, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Text(
          formatDuration(duration),
          style: theme.textTheme.titleSmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: isActive ? style.fg : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
