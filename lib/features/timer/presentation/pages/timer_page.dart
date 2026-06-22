import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';
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

    ref.listen<AsyncValue<TimerWsFriendActivity>>(timerFriendActivityProvider, (
      _,
      next,
    ) {
      next.whenData((activity) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendActivityMessage(activity))),
        );
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
          const Expanded(flex: 2, child: TimerDashboard()),

          // 구분선
          const Divider(height: 1),

          const Expanded(flex: 3, child: TimerHistoryList()),
        ],
      ),
    );
  }
}

/// 친구 활동 이벤트(`timer.friend_activity`)를 SnackBar 문구로 변환한다.
///
/// 백엔드 `TimerAction` 공식 값(start/pause/resume/stop)만 매핑하고,
/// 그 외 미정의 action은 generic fallback 문구로 처리한다.
/// `displayName`이 없거나 빈 문자열이면 `친구`로 대체한다.
String friendActivityMessage(TimerWsFriendActivity activity) {
  final displayName = activity.displayName?.trim();
  final friendName = displayName == null || displayName.isEmpty
      ? '친구'
      : displayName;
  final timerTitle = activity.timerTitle?.trim();
  final target = timerTitle == null || timerTitle.isEmpty
      ? '타이머'
      : '$timerTitle 타이머';

  return switch (activity.action) {
    'start' => '$friendName님이 $target를 시작했습니다',
    'pause' => '$friendName님이 $target를 일시정지했습니다',
    'resume' => '$friendName님이 $target를 재개했습니다',
    'stop' => '$friendName님이 $target를 정지했습니다',
    _ => '$friendName님의 타이머 상태가 변경되었습니다',
  };
}

const _stopTimerConfirmTitle = '타이머 종료';
const _stopTimerConfirmContent =
    '정말 종료하시겠습니까?\n정지할 경우 다시 시작이 불가합니다.\n일시 정지를 이용해 주세요.';

/// 타이머 정지 확인 다이얼로그. 사용자가 종료를 확인하면 true.
Future<bool> _confirmStopTimer(BuildContext context) {
  return showConfirmDialog(
    context,
    title: _stopTimerConfirmTitle,
    content: _stopTimerConfirmContent,
    confirmText: '종료',
    destructive: true,
  );
}

/// 타이머 대시보드 (상단 영역)
///
/// 디지털 시계와 제어 버튼을 포함합니다.
class TimerDashboard extends ConsumerWidget {
  const TimerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeTimerAsync = ref.watch(activeTimerProvider);
    final timerTicker = ref.watch(timerTickerProvider);
    final controllerState = ref.watch(timerControllerProvider);

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
              timerTicker.when(
                data: (duration) =>
                    DigitalClock(duration: duration, compact: compact),
                loading: () =>
                    DigitalClock(duration: Duration.zero, compact: compact),
                error: (error, stack) =>
                    DigitalClock(duration: Duration.zero, compact: compact),
              ),
              SizedBox(height: compact ? 8 : 12),
              activeTimerAsync.when(
                data: (activeTimer) =>
                    CurrentTaskDisplay(timer: activeTimer, compact: compact),
                loading: () =>
                    CurrentTaskDisplay(timer: null, compact: compact),
                error: (error, stack) =>
                    CurrentTaskDisplay(timer: null, compact: compact),
              ),
              SizedBox(height: compact ? 10 : 16),
              TimerControlButton(
                activeTimer: activeTimerAsync.when(
                  data: (timer) => timer,
                  loading: () => null,
                  error: (error, stack) => null,
                ),
                isLoading: controllerState.isLoading,
                onStart: () => _showStartTimerDialog(context, ref),
                onStop: () => _stopTimer(context, ref),
                onPause: () => _pauseTimer(context, ref),
                onResume: () => _resumeTimer(context, ref),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final title = controller.text.trim().isEmpty
                  ? '새 작업'
                  : controller.text.trim();
              Navigator.of(dialogContext).pop();
              try {
                await ref
                    .read(timerControllerProvider.notifier)
                    .startTimer(title: title);
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
            },
            child: const Text('시작'),
          ),
        ],
      ),
    );
  }

  /// 타이머 정지
  void _stopTimer(BuildContext context, WidgetRef ref) async {
    final activeTimer = ref
        .read(activeTimerProvider)
        .when(
          data: (timer) => timer,
          loading: () => null,
          error: (_, _) => null,
        );

    if (activeTimer == null || activeTimer.status == TimerStatus.completed) {
      ref.invalidate(activeTimerProvider);
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
      ref.invalidate(activeTimerProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('타이머가 정지되었습니다'),
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
            content: Text('타이머 정지 실패: ${error.toString()}'),
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
}

/// 디지털 시계 위젯
///
/// HH:MM:SS 형식으로 경과 시간을 크게 표시합니다.
class DigitalClock extends StatelessWidget {
  final Duration duration;
  final bool compact;

  const DigitalClock({super.key, required this.duration, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = formatDuration(duration);

    return Text(
      timeText,
      style: theme.textTheme.displayLarge?.copyWith(
        fontFamily: 'monospace', // 등폭 폰트 사용
        fontSize: compact ? 46 : 56,
        fontWeight: FontWeight.w300,
        color: duration.inSeconds > 0
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: compact ? 0 : 4,
      ),
    );
  }
}

/// 현재 작업 표시 위젯
class CurrentTaskDisplay extends StatelessWidget {
  final TimerRead? timer;
  final bool compact;

  const CurrentTaskDisplay({
    super.key,
    required this.timer,
    this.compact = false,
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

    final statusText = timer!.status == TimerStatus.running ? '실행 중' : '일시정지';
    final statusColor = timer!.status == TimerStatus.running
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

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
        Text(
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
class TimerControlButton extends StatelessWidget {
  final TimerRead? activeTimer;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const TimerControlButton({
    super.key,
    required this.activeTimer,
    required this.isLoading,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (activeTimer == null) {
      return FloatingActionButton(
        onPressed: onStart,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(
          Icons.play_arrow,
          size: 32,
          color: theme.colorScheme.onPrimary,
        ),
      );
    } else if (activeTimer!.status == TimerStatus.running) {
      // 위계: 자주 쓰는 일시정지를 큰 주 버튼(primary), 비가역 정지는
      // 작은 보조 버튼(error)으로 + 간격을 넓혀 오탭을 방지한다.
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.small(
            onPressed: onStop,
            tooltip: '정지',
            backgroundColor: theme.colorScheme.error,
            child: Icon(Icons.stop, color: theme.colorScheme.onError),
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
            tooltip: '정지',
            backgroundColor: theme.colorScheme.error,
            child: Icon(Icons.stop, color: theme.colorScheme.onError),
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
/// RUNNING/PAUSED일 때 실시간 경과 시간을 표시하고, 일시정지·재개·정지 버튼을 제공합니다.
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
    final style = _statusStyle(context);
    final activeTimer = ref
        .watch(activeTimerProvider)
        .when(data: (t) => t, loading: () => null, error: (_, _) => null);
    final tickerAsync = ref.watch(timerTickerProvider);
    final controllerLoading = ref.watch(timerControllerProvider).isLoading;

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

    final bool useLiveTicker =
        timer.status == TimerStatus.running && timer.id == activeTimer?.id;
    final Duration duration = useLiveTicker
        ? tickerAsync.when(
            data: (d) => d,
            loading: () => Duration(seconds: timer.elapsedTime),
            error: (_, _) => Duration(seconds: timer.elapsedTime),
          )
        : Duration(seconds: timer.elapsedTime);

    final isActive =
        timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;
    final isThisLoading = controllerLoading;

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
              if (isThisLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              else ...[
                if (timer.status == TimerStatus.running)
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
                  ),
                if (timer.status == TimerStatus.paused)
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
                  icon: Icon(Icons.stop, color: theme.colorScheme.error),
                  onPressed: () async {
                    final confirmed = await _confirmStopTimer(context);
                    if (!context.mounted || !confirmed) return;
                    await _runTimerAction(
                      context,
                      ref,
                      action: () => ref
                          .read(timerControllerProvider.notifier)
                          .stopTimer(timerId: timer.id),
                      errorLabel: '정지',
                    );
                  },
                  tooltip: '정지',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
