import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/network/server_clock.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/timer/presentation/widgets/timer_dial.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';
import 'package:momeet/shared/widgets/error_banner.dart';

/// 타이머 대시보드 페이지
///
/// 실시간 타이머 표시, 제어 버튼, 히스토리 목록을 제공합니다.
class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastError = ref.watch(timerWsLastErrorProvider);

    ref.listen<AsyncValue<TimerWsTimerEvent>>(timerFriendActivityProvider, (
      _,
      next,
    ) {
      next.whenData((event) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendActivityMessage(event))));
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('타이머'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ErrorBanner(
              message: lastError?.message,
              onDismiss: () =>
                  ref.read(timerWsLastErrorProvider.notifier).setError(null),
            ),
          ),
          const Expanded(flex: 3, child: TimerDashboard()),

          // 구분선
          const Divider(height: 1),

          const Expanded(flex: 2, child: TimerHistoryList()),
        ],
      ),
    );
  }
}

/// 친구의 타이머 이벤트를 SnackBar 문구로 변환한다.
///
/// `payload.action` 중 start/pause/resume/stop/expire만 매핑하고,
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
    'expire' => '$friendName님의 $target가 끝났습니다',
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

/// 새 작업 시작 다이얼로그에서 고를 수 있는 집중 시간
const _focusDurationPresets = [
  Duration(minutes: 15),
  Duration(minutes: 25),
  Duration(minutes: 45),
  Duration(minutes: 60),
];

/// 시간이 끝난 타이머를 한 번에 늘리는 시간
const _extendBy = Duration(minutes: 5);

/// 새 작업 시작 다이얼로그에 입력할 수 있는 가장 긴 집중 시간 (분)
const _maxFocusMinutes = 600;

/// [text]가 1~[_maxFocusMinutes] 사이의 분이면 그 값, 아니면 null
int? _focusMinutes(String text) {
  final minutes = int.tryParse(text);
  if (minutes == null || minutes < 1 || minutes > _maxFocusMinutes) {
    return null;
  }
  return minutes;
}

/// 타이머 대시보드 (상단 영역)
///
/// 다이얼, 디지털 시계, 제어 버튼을 포함합니다.
/// 활성 타이머가 없으면 다이얼을 끌어 새 작업의 집중 시간을 고르고, 있으면 다이얼은 남은 시간만 보여 줍니다.
class TimerDashboard extends ConsumerStatefulWidget {
  const TimerDashboard({super.key});

  @override
  ConsumerState<TimerDashboard> createState() => _TimerDashboardState();
}

class _TimerDashboardState extends ConsumerState<TimerDashboard> {
  /// 다이얼로 고른 새 작업의 집중 시간
  Duration _pendingDuration = defaultFocusDuration;

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
    final timeUp =
        activeTimer != null &&
        (remaining == Duration.zero || isTimeUp(activeTimer, now));
    final dialColor = timeUp
        ? theme.colorScheme.error
        : activeTimer?.status == TimerStatus.paused
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 230;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: activeTimer == null
                    ? TimerDial(
                        remaining: _pendingDuration,
                        color: dialColor,
                        onChanged: (duration) =>
                            setState(() => _pendingDuration = duration),
                      )
                    : TimerDial(
                        remaining: remaining,
                        face: dialFaceFor(
                          Duration(seconds: activeTimer.allocatedDuration),
                        ),
                        color: dialColor,
                      ),
              ),
              SizedBox(height: compact ? 4 : 8),
              DigitalClock(
                duration: activeTimer == null ? _pendingDuration : remaining,
                timeUp: timeUp,
                idle: activeTimer == null,
                compact: compact,
              ),
              SizedBox(height: compact ? 8 : 12),
              CurrentTaskDisplay(
                timer: activeTimer,
                timeUp: timeUp,
                compact: compact,
                onTodoChanged: (todo) {
                  if (!context.mounted) return;
                  ref.read(myActiveTimersProvider.notifier).updateTodo(todo);
                },
              ),
              SizedBox(height: compact ? 10 : 16),
              TimerControlButton(
                activeTimer: activeTimer,
                starting: controllerState.isLoading,
                timeUp: timeUp,
                onStart: () => _showStartTimerDialog(context, ref),
                onStop: () => _stopTimer(context, ref),
                onPause: () => _pauseTimer(context, ref),
                onResume: () => _resumeTimer(context, ref),
                onExtend: () => _extendTimer(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 타이머 시작 다이얼로그 표시
  void _showStartTimerDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final minutesController = TextEditingController(
      text: '${_pendingDuration.inMinutes}',
    );
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('새 작업 시작'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '작업명',
                hintText: '어떤 작업을 시작할까요?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: minutesController,
              builder: (_, value, _) {
                final minutes = _focusMinutes(value.text);
                return Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final preset in _focusDurationPresets)
                      ChoiceChip(
                        label: Text('${preset.inMinutes}분'),
                        selected: preset.inMinutes == minutes,
                        onSelected: (_) =>
                            minutesController.text = '${preset.inMinutes}',
                      ),
                    SizedBox(
                      width: 96,
                      child: TextFormField(
                        controller: minutesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          suffixText: '분',
                          border: const OutlineInputBorder(),
                          errorText: minutes == null
                              ? '1~$_maxFocusMinutes분'
                              : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: minutesController,
            builder: (_, value, _) {
              final minutes = _focusMinutes(value.text);
              return FilledButton(
                onPressed: minutes == null
                    ? null
                    : () async {
                        final title = controller.text.trim().isEmpty
                            ? '새 작업'
                            : controller.text.trim();
                        Navigator.of(dialogContext).pop();
                        try {
                          await ref
                              .read(timerControllerProvider.notifier)
                              .startTimer(
                                title: title,
                                allocatedDurationSeconds: minutes * 60,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('타이머를 시작했습니다')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('타이머 시작 실패: $e'),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('시작'),
              );
            },
          ),
        ],
      ),
    );
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
        fontSize: compact ? 28 : 36,
        fontWeight: FontWeight.w300,
        color: timeUp
            ? theme.colorScheme.error
            : !idle && duration.inSeconds > 0
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: compact ? 0 : 4,
      ),
    );
  }
}

/// 현재 작업 표시 위젯
///
/// 집중 시간이 끝나면([timeUp]) 상태를 '시간 종료'로 표시합니다.
/// 연결된 Todo가 있으면 제목 옆에 Todo 상태를 표시하고, 일시정지 중에는 그 자리에서 바꿀 수 있습니다.
/// 바꾼 뒤 서버가 돌려준 Todo로 [onTodoChanged]를 부릅니다.
class CurrentTaskDisplay extends StatelessWidget {
  final TimerRead? timer;
  final bool timeUp;
  final bool compact;
  final ValueChanged<TodoRead>? onTodoChanged;

  const CurrentTaskDisplay({
    super.key,
    required this.timer,
    this.timeUp = false,
    this.compact = false,
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

    final statusText = timeUp
        ? '시간 종료'
        : timer!.status == TimerStatus.running
        ? '실행 중'
        : '일시정지';
    final statusColor = timeUp || timer!.status != TimerStatus.running
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    final todo = timer!.todo;
    final todoIconSize = compact ? 20.0 : 24.0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            statusText,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (todo != null) ...[
              if (timer!.status == TimerStatus.paused)
                TodoStatusSelector(
                  todo: todo,
                  iconSize: todoIconSize,
                  onChanged: onTodoChanged,
                )
              else
                Icon(
                  todo.status.icon,
                  color: todo.status.color(context),
                  size: todoIconSize,
                  semanticLabel: todo.status.label,
                ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                taskName,
                style:
                    (compact
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!compact && timer!.startedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            '시작: ${formatTime(timer!.startedAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

/// 타이머 제어 버튼
///
/// 일시정지·재개는 누르는 즉시 [activeTimer]에 반영되므로 버튼을 그대로 둔다.
/// 새 타이머 시작만 응답을 기다리고([starting]), 그동안 시작 버튼 안에 진행 표시를 둔다.
/// 집중 시간이 끝나면([timeUp]) 일시정지·재개 대신 연장([onExtend]) 버튼을 둔다.
class TimerControlButton extends StatelessWidget {
  final TimerRead? activeTimer;
  final bool starting;
  final bool timeUp;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onExtend;

  const TimerControlButton({
    super.key,
    required this.activeTimer,
    required this.starting,
    required this.timeUp,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeTimer == null) {
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
        ],
      );
    }
  }
}

/// 타이머 히스토리 목록
class TimerHistoryList extends ConsumerWidget {
  const TimerHistoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(height: 16),
          Expanded(
            child: historyAsync.when(
              data: (timers) => timers.isEmpty
                  ? _buildEmptyState(context)
                  : _buildHistoryList(context, timers),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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

/// 타이머 히스토리 항목
///
/// RUNNING/PAUSED일 때 실시간 남은 시간을, 끝난 타이머는 경과 시간을 표시하고, 일시정지·재개·완료 버튼을 제공합니다.
/// 집중 시간이 끝난 타이머는 일시정지·재개 대신 연장 버튼을 둡니다.
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

  ({IconData icon, Color bg, Color fg, String label}) _statusStyle(
    BuildContext context,
    TimerRead timer,
  ) {
    final cs = Theme.of(context).colorScheme;
    switch (timer.status) {
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
      default:
        return (
          icon: Icons.check_circle_outline,
          bg: cs.primaryContainer,
          fg: cs.onPrimaryContainer,
          label: '완료',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 명령 응답 전 값이나 받은 응답을 목록을 다시 읽기 전에 먼저 보인다
    final timer = timerView(ref.watch(timerViewsProvider), this.timer);
    final style = _statusStyle(context, timer);
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: style.fg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text('$startTime - $endTime'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatDuration(duration),
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: isActive ? style.fg : theme.colorScheme.primary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
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
          ],
        ),
      ),
    );
  }
}
