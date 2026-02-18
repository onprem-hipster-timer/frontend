import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/shared/api/models/todo_status.dart';

/// 타이머 기능이 통합된 Todo Tree Tile
///
/// Todo 정보와 함께 타이머 시간, 재생/정지 버튼을 표시합니다.
/// 활성 타이머가 있는 경우 1초마다 UI가 갱신됩니다.
class TodoTreeTileWithTimer extends ConsumerWidget {
  final TodoTreeNode node;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final bool isExpanded;

  const TodoTreeTileWithTimer({
    super.key,
    required this.node,
    this.onTap,
    this.onExpand,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 타이머 집계 데이터 조회
    final aggregationAsync = ref.watch(todoTimerAggregationProvider(node.id));

    // 활성 타이머 스트림 조회 (최적화된 리빌드)
    final activeTimerState = ref.watch(
      activeTimerStreamProvider.select((asyncValue) {
        return asyncValue.when(
          data: (activeStates) => activeStates[node.id],
          loading: () => null,
          error: (error, stack) => null,
        );
      }),
    );

    return Container(
      margin: EdgeInsets.only(left: node.depth * 16.0),
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: aggregationAsync.when(
          loading: () => _buildTileLoading(context, theme),
          error: (error, stack) => _buildTileError(context, theme, error),
          data: (aggregation) => _buildTile(
            context,
            theme,
            ref,
            aggregation,
            activeTimerState,
          ),
        ),
      ),
    );
  }

  /// 로딩 상태 타일
  Widget _buildTileLoading(BuildContext context, ThemeData theme) {
    return ListTile(
      leading: _buildExpandIcon(theme),
      title: Text(node.todo.title),
      subtitle: Text(_getStatusText(node.todo.status)),
      trailing: const SizedBox(
        width: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      onTap: onTap,
    );
  }

  /// 에러 상태 타일
  Widget _buildTileError(BuildContext context, ThemeData theme, Object error) {
    return ListTile(
      leading: _buildExpandIcon(theme),
      title: Text(node.todo.title),
      subtitle: Text('타이머 로드 실패: ${error.toString()}'),
      trailing: SizedBox(
        width: 100,
        child: Icon(Icons.error, color: theme.colorScheme.error),
      ),
      onTap: onTap,
    );
  }

  /// 메인 타일 (타이머 정보 포함)
  Widget _buildTile(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    TodoTimerAggregation? aggregation,
    ActiveTimerState? activeTimerState,
  ) {
    final hasActiveTimer = activeTimerState != null;
    final displayTime = hasActiveTimer
        ? activeTimerState.formattedTime
        : aggregation?.totalTimeFormatted ?? '00:00:00';

    return ListTile(
      leading: _buildExpandIcon(theme),
      title: Row(
        children: [
          Expanded(
            child: Text(
              node.todo.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                decoration: node.todo.status == TodoStatus.done
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (aggregation != null && aggregation.totalElapsedSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasActiveTimer
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayTime,
                style: TextStyle(
                  color: hasActiveTimer
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getStatusText(node.todo.status)),
          if (aggregation != null && aggregation.ownElapsedSeconds > 0)
            Text(
              '본인: ${aggregation.ownTimeFormatted}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
      trailing: TimerControlButtons(
        todoId: node.id,
        aggregation: aggregation,
        activeTimerState: activeTimerState,
      ),
      onTap: onTap,
    );
  }

  /// 확장/축소 아이콘
  Widget _buildExpandIcon(ThemeData theme) {
    if (!node.hasChildren) {
      return SizedBox(
        width: 24,
        child: Icon(
          Icons.radio_button_unchecked,
          size: 16,
          color: theme.colorScheme.outline,
        ),
      );
    }

    return IconButton(
      icon: Icon(
        isExpanded ? Icons.expand_more : Icons.chevron_right,
        color: theme.colorScheme.primary,
      ),
      onPressed: onExpand,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
    );
  }

  /// 상태 텍스트 반환
  String _getStatusText(TodoStatus status) {
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
        return status.toString();
    }
  }
}

/// 타이머 제어 버튼들
class TimerControlButtons extends ConsumerWidget {
  final String todoId;
  final TodoTimerAggregation? aggregation;
  final ActiveTimerState? activeTimerState;

  const TimerControlButtons({
    super.key,
    required this.todoId,
    this.aggregation,
    this.activeTimerState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mutations = ref.watch(timerMutationsProvider);

    final hasActiveTimer = activeTimerState != null;
    final isRunning = activeTimerState?.isRunning ?? false;

    return SizedBox(
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (mutations.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (hasActiveTimer) ...[
            // 활성 타이머가 있는 경우: 재생/일시정지 버튼
            IconButton(
              icon: Icon(
                isRunning ? Icons.pause : Icons.play_arrow,
                color: isRunning
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              onPressed: () => _handleTimerToggle(ref, activeTimerState!),
              tooltip: isRunning ? '일시정지' : '재개',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: Icon(
                Icons.stop,
                color: theme.colorScheme.outline,
              ),
              onPressed: () =>
                  _handleTimerStop(context, ref, activeTimerState!),
              tooltip: '정지',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ] else ...[
            // 활성 타이머가 없는 경우: 시작 버튼
            IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: theme.colorScheme.primary,
              ),
              onPressed: () => _handleTimerStart(context, ref),
              tooltip: '타이머 시작',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 32), // 정렬을 위한 여백
          ],
        ],
      ),
    );
  }

  /// 타이머 시작
  Future<void> _handleTimerStart(BuildContext context, WidgetRef ref) async {
    try {
      // 현재는 타이머 생성 API가 없으므로 placeholder 구현
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('타이머 기능이 곧 구현됩니다')),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('타이머 시작 실패: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 타이머 일시정지/재개 토글
  Future<void> _handleTimerToggle(
      WidgetRef ref, ActiveTimerState timerState) async {
    try {
      // 현재는 타이머 제어 API가 없으므로 placeholder 구현
      debugPrint('타이머 토글: ${timerState.timerId}');
    } catch (error) {
      // 에러는 mutations provider의 state에서 처리됨
      debugPrint('타이머 토글 실패: $error');
    }
  }

  /// 타이머 정지 (확인 다이얼로그 포함)
  Future<void> _handleTimerStop(
    BuildContext context,
    WidgetRef ref,
    ActiveTimerState timerState,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('타이머 정지'),
        content:
            Text('현재 진행 중인 타이머를 정지하시겠습니까?\n경과 시간: ${timerState.formattedTime}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('정지'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 현재는 타이머 정지 API가 없으므로 placeholder 구현
        debugPrint('타이머 정지: ${timerState.timerId}');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('타이머 정지 기능이 곧 구현됩니다')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('타이머 정지 실패: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
