import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// Todo 상세 정보 시트
///
/// 단건 조회 API로 최신 데이터를 가져오고,
/// Todo별 타이머 히스토리 및 활성 타이머를 표시합니다.
class TodoDetailSheet extends ConsumerWidget {
  final String todoId;

  const TodoDetailSheet({super.key, required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final todoAsync = ref.watch(todoByIdProvider(todoId));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: todoAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildError(context, theme, error, ref),
            data: (todo) => _buildContent(
              context,
              theme,
              ref,
              todo,
              scrollController,
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(
    BuildContext context,
    ThemeData theme,
    Object error,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Todo를 불러올 수 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(todoByIdProvider(todoId)),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    TodoRead todo,
    ScrollController scrollController,
  ) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildHandle(theme)),
        SliverToBoxAdapter(child: _buildHeader(context, theme, ref, todo)),
        SliverToBoxAdapter(
          child: _ActiveTimerBanner(todoId: todoId, ref: ref),
        ),
        if (todo.description != null && todo.description!.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildDescription(theme, todo.description!),
          ),
        if (todo.tags.isNotEmpty)
          SliverToBoxAdapter(child: _buildTags(theme, todo.tags)),
        if (todo.deadline != null)
          SliverToBoxAdapter(child: _buildDeadline(theme, todo.deadline!)),
        SliverToBoxAdapter(
          child: _TimerHistorySection(todoId: todoId),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    TodoRead todo,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: todo.status == TodoStatus.done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusChip(status: todo.status),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '수정',
            onPressed: () {
              Navigator.pop(context);
              showTodoFormSheet(context, todo: todo);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '닫기',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ThemeData theme, String description) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notes,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '설명',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTags(ThemeData theme, List<TagRead> tags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.label_outline,
                size: 16,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                '태그',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map(
                  (tag) => Chip(
                    label: Text(tag.name),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadline(ThemeData theme, DateTime deadline) {
    final now = DateTime.now();
    final isOverdue = deadline.isBefore(now) && true;
    final color = isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Icon(Icons.event, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '마감: ${_formatDate(deadline)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
          if (isOverdue) ...[
            const SizedBox(width: 6),
            Chip(
              label: const Text('마감 초과'),
              backgroundColor: theme.colorScheme.errorContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 11,
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

/// 상태 칩 위젯
class _StatusChip extends StatelessWidget {
  final TodoStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(_label),
      backgroundColor: _color(theme).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: _color(theme),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String get _label {
    switch (status) {
      case TodoStatus.unscheduled:
        return '미예정';
      case TodoStatus.scheduled:
        return '예정됨';
      case TodoStatus.done:
        return '완료';
      case TodoStatus.cancelled:
        return '취소됨';
      default:
        return '알 수 없음';
    }
  }

  Color _color(ThemeData theme) {
    switch (status) {
      case TodoStatus.done:
        return Colors.green;
      case TodoStatus.cancelled:
        return theme.colorScheme.error;
      case TodoStatus.scheduled:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

/// 활성 타이머 배너
class _ActiveTimerBanner extends ConsumerWidget {
  final String todoId;
  final WidgetRef ref;

  const _ActiveTimerBanner({required this.todoId, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeTimerAsync = ref.watch(todoActiveTimerProvider(todoId));

    return activeTimerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (timer) {
        if (timer == null) return const SizedBox.shrink();

        final isRunning = timer.status == TimerStatus.running;
        final color = isRunning
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer;
        final onColor = isRunning
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSecondaryContainer;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isRunning ? Icons.timer : Icons.pause_circle_outline,
                color: onColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isRunning ? '타이머 실행 중' : '타이머 일시정지',
                style: theme.textTheme.labelLarge?.copyWith(color: onColor),
              ),
              const Spacer(),
              _TimerElapsedText(timer: timer, onColor: onColor),
              const SizedBox(width: 8),
              if (isRunning)
                _TimerActionButton(
                  icon: Icons.pause,
                  tooltip: '일시정지',
                  color: onColor,
                  onPressed: () => ref
                      .read(timerControllerProvider.notifier)
                      .pauseTimer(timerId: timer.id),
                )
              else
                _TimerActionButton(
                  icon: Icons.play_arrow,
                  tooltip: '재개',
                  color: onColor,
                  onPressed: () => ref
                      .read(timerControllerProvider.notifier)
                      .resumeTimer(timerId: timer.id),
                ),
              _TimerActionButton(
                icon: Icons.stop,
                tooltip: '정지',
                color: onColor,
                onPressed: () => ref
                    .read(timerControllerProvider.notifier)
                    .stopTimer(timerId: timer.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimerElapsedText extends StatelessWidget {
  final TimerRead timer;
  final Color onColor;

  const _TimerElapsedText({required this.timer, required this.onColor});

  @override
  Widget build(BuildContext context) {
    final elapsed = _calcElapsed();
    return Text(
      _formatDuration(elapsed),
      style: TextStyle(
        color: onColor,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  int _calcElapsed() {
    if (timer.status == TimerStatus.running && timer.startedAt != null) {
      final now = DateTime.now();
      return timer.elapsedTime + now.difference(timer.startedAt!).inSeconds;
    }
    return timer.elapsedTime;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TimerActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _TimerActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}

/// 타이머 히스토리 섹션
class _TimerHistorySection extends ConsumerWidget {
  final String todoId;

  const _TimerHistorySection({required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timersAsync = ref.watch(todoTimersProvider(todoId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '타이머 히스토리',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => ref.invalidate(todoTimersProvider(todoId)),
                tooltip: '새로고침',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          timersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => _buildTimerError(theme, error, ref),
            data: (timers) => _buildTimerList(theme, timers),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerError(ThemeData theme, Object error, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '타이머 히스토리를 불러오지 못했습니다',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(todoTimersProvider(todoId)),
            child: const Text('재시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerList(ThemeData theme, List<TimerRead> timers) {
    if (timers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.timer_off_outlined,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              '타이머 기록이 없습니다',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // 활성 타이머(RUNNING/PAUSED)를 상단, 완료(COMPLETED)를 하단으로 정렬
    final sorted = [...timers]..sort((a, b) {
        final aActive = a.status == TimerStatus.running ||
            a.status == TimerStatus.paused;
        final bActive = b.status == TimerStatus.running ||
            b.status == TimerStatus.paused;
        if (aActive && !bActive) return -1;
        if (!aActive && bActive) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    int totalElapsed = timers.fold(0, (sum, t) => sum + t.elapsedTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 총 시간 요약
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_filled,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '총 시간: ${_formatDuration(totalElapsed)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${timers.length}개 세션',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 타이머 목록
        ...sorted.map((timer) => _TimerHistoryItem(timer: timer)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// 타이머 히스토리 아이템
class _TimerHistoryItem extends StatelessWidget {
  final TimerRead timer;

  const _TimerHistoryItem({required this.timer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = timer.status == TimerStatus.running ||
        timer.status == TimerStatus.paused;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              )
            : null,
      ),
      child: Row(
        children: [
          _StatusIcon(status: timer.status),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer.title ?? '제목 없음',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(timer.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDuration(timer.elapsedTime),
            style: theme.textTheme.labelLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusIcon extends StatelessWidget {
  final TimerStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    switch (status) {
      case TimerStatus.running:
        icon = Icons.play_circle_filled;
        color = theme.colorScheme.primary;
      case TimerStatus.paused:
        icon = Icons.pause_circle_filled;
        color = theme.colorScheme.secondary;
      case TimerStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
      case TimerStatus.cancelled:
        icon = Icons.cancel;
        color = theme.colorScheme.error;
      default:
        icon = Icons.circle_outlined;
        color = theme.colorScheme.onSurfaceVariant;
    }

    return Icon(icon, color: color, size: 20);
  }
}

/// Todo 상세 시트를 표시하는 헬퍼 함수
Future<void> showTodoDetailSheet(BuildContext context, String todoId) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TodoDetailSheet(todoId: todoId),
  );
}
