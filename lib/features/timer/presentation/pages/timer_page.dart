import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/export.dart';

/// 타이머 대시보드 페이지
///
/// 실시간 타이머 표시, 제어 버튼, 히스토리 목록을 제공합니다.
class TimerPage extends ConsumerWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('타이머'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: const Column(
        children: [
          // 상단: 디지털 시계 및 제어 버튼
          Expanded(
            flex: 2,
            child: TimerDashboard(),
          ),

          // 구분선
          Divider(height: 1),

          // 하단: 히스토리 목록
          Expanded(
            flex: 3,
            child: TimerHistoryList(),
          ),
        ],
      ),
    );
  }
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          // 디지털 시계
          timerTicker.when(
            data: (duration) => DigitalClock(duration: duration),
            loading: () => const DigitalClock(duration: Duration.zero),
            error: (error, stack) => const DigitalClock(duration: Duration.zero),
          ),

          const SizedBox(height: 32),

          // 현재 작업 표시
          activeTimerAsync.when(
            data: (activeTimer) => CurrentTaskDisplay(timer: activeTimer),
            loading: () => const CurrentTaskDisplay(timer: null),
            error: (error, stack) => const CurrentTaskDisplay(timer: null),
          ),

          const SizedBox(height: 40),

          // 제어 버튼
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
  }

  /// 타이머 시작 다이얼로그 표시
  void _showStartTimerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 작업 시작'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '작업명',
                hintText: '어떤 작업을 시작할까요?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '타이머 생성 기능이 곧 구현됩니다.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('타이머 생성 API가 곧 구현됩니다')),
              );
            },
            child: const Text('시작'),
          ),
        ],
      ),
    );
  }

  /// 타이머 정지
  void _stopTimer(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(timerControllerProvider.notifier).stopTimer();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('타이머가 정지되었습니다')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일시정지 실패: ${error.toString()}')),
        );
      }
    }
  }

  /// 타이머 재개
  void _resumeTimer(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(timerControllerProvider.notifier).resumeTimer();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('재개 실패: ${error.toString()}')),
        );
      }
    }
  }
}

/// 디지털 시계 위젯
///
/// HH:MM:SS 형식으로 경과 시간을 크게 표시합니다.
class DigitalClock extends StatelessWidget {
  final Duration duration;

  const DigitalClock({
    super.key,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = formatDuration(duration);

    return Text(
      timeText,
      style: theme.textTheme.displayLarge?.copyWith(
        fontFamily: 'monospace', // 등폭 폰트 사용
        fontSize: 56,
        fontWeight: FontWeight.w300,
        color: duration.inSeconds > 0
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 4,
      ),
    );
  }
}

/// 현재 작업 표시 위젯
class CurrentTaskDisplay extends StatelessWidget {
  final TimerRead? timer;

  const CurrentTaskDisplay({
    super.key,
    required this.timer,
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

    final taskName = timer!.title ??
                     timer!.todo?.title ??
                     timer!.schedule?.title ??
                     '알 수 없는 작업';

    final statusText = timer!.status == 'RUNNING' ? '실행 중' : '일시정지';
    final statusColor = timer!.status == 'RUNNING'
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        const SizedBox(height: 8),
        Text(
          taskName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        if (timer!.startedAt != null) ...[
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
      // 활성 타이머 없음: 시작 버튼
      return FloatingActionButton.large(
        onPressed: onStart,
        backgroundColor: theme.colorScheme.primary,
        child: Icon(
          Icons.play_arrow,
          size: 48,
          color: theme.colorScheme.onPrimary,
        ),
      );
    } else if (activeTimer!.status == 'RUNNING') {
      // 실행 중: 일시정지 및 정지 버튼
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: onPause,
            backgroundColor: theme.colorScheme.secondary,
            child: Icon(
              Icons.pause,
              color: theme.colorScheme.onSecondary,
            ),
          ),
          const SizedBox(width: 24),
          FloatingActionButton.large(
            onPressed: onStop,
            backgroundColor: theme.colorScheme.error,
            child: Icon(
              Icons.stop,
              size: 32,
              color: theme.colorScheme.onError,
            ),
          ),
        ],
      );
    } else {
      // 일시정지 중: 재개 및 정지 버튼
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: onResume,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.play_arrow,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 24),
          FloatingActionButton.large(
            onPressed: onStop,
            backgroundColor: theme.colorScheme.error,
            child: Icon(
              Icons.stop,
              size: 32,
              color: theme.colorScheme.onError,
            ),
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
            '최근 기록',
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
          Text(
            '완료된 타이머가 없습니다',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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
class TimerHistoryItem extends StatelessWidget {
  final TimerRead timer;

  const TimerHistoryItem({
    super.key,
    required this.timer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final taskName = timer.title ??
                     timer.todo?.title ??
                     timer.schedule?.title ??
                     '알 수 없는 작업';

    final startTime = timer.startedAt != null ? formatTime(timer.startedAt!) : '--:--';
    final endTime = timer.endedAt != null ? formatTime(timer.endedAt!) : '--:--';
    final duration = Duration(seconds: timer.elapsedTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.timer,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          taskName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('$startTime - $endTime'),
        trailing: Text(
          formatDuration(duration),
          style: theme.textTheme.titleSmall?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
