// 재귀적 Todo 트리 타일 위젯
//
// 계층형 할 일 트리의 각 노드를 렌더링합니다.
// 드래그 앤 드롭으로 부모 변경을 지원합니다.
import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/core/utils/time_formatters.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart'
    show defaultFocusDuration, timerControllerProvider;
import 'package:momeet/features/timer/presentation/widgets/start_timer_dialog.dart';
import 'package:momeet/router.dart';

import '../providers/timer_providers.dart';
import '../providers/todo_provider.dart';
import '../utils/todo_tree_builder.dart';
import '../utils/todo_actions.dart';
import 'todo_status_selector.dart';

/// 들여쓰기 단위 (깊이당 픽셀)
const double kIndentWidth = 24.0;

/// 드래그 피드백 투명도
const double kDraggingOpacity = 0.5;

/// 드롭 대상 하이라이트 색상
const Color kDropTargetColor = Colors.blue;

/// 드롭 불가 색상
const Color kInvalidDropColor = Colors.red;

/// Todo 트리 타일 위젯
///
/// 단일 Todo 노드와 그 자식들을 재귀적으로 렌더링합니다.
class TodoTreeTile extends ConsumerWidget {
  /// 렌더링할 트리 노드
  final TodoTreeNode node;

  /// 전체 트리 (드롭 유효성 검사용)
  final TodoTree tree;

  /// 타일 탭 콜백
  final void Function(TodoRead todo)? onTap;

  /// 확장 토글 콜백 (외부 제어용)
  final void Function(String todoId)? onToggleExpand;

  /// 기본 확장 상태 (expandedTodoIdsProvider 사용하지 않을 때)
  final bool? initiallyExpanded;

  const TodoTreeTile({
    super.key,
    required this.node,
    required this.tree,
    this.onTap,
    this.onToggleExpand,
    this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = node.todo;
    final depth = node.depth;
    final hasChildren = node.hasChildren;

    // 확장 상태 읽기
    final expandedIds = ref.watch(expandedTodoIdsProvider);
    final isExpanded = initiallyExpanded ?? expandedIds.contains(todo.id);

    // 드래그 상태
    final draggingId = ref.watch(draggingTodoIdProvider);
    final isDragging = draggingId == todo.id;

    // 선택 상태
    final selectedId = ref.watch(selectedTodoIdProvider);
    final isSelected = selectedId == todo.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 현재 노드 - DragTarget으로 감싸기
        _buildDragTarget(
          context,
          ref,
          child: _buildDraggable(
            context,
            ref,
            child: _buildTileContent(
              context,
              ref,
              todo: todo,
              depth: depth,
              hasChildren: hasChildren,
              isExpanded: isExpanded,
              isSelected: isSelected,
              isDragging: isDragging,
            ),
          ),
        ),

        // 자식 노드들 (확장된 경우에만)
        if (hasChildren && isExpanded)
          ...node.children.map(
            (childNode) => TodoTreeTile(
              node: childNode,
              tree: tree,
              onTap: onTap,
              onToggleExpand: onToggleExpand,
            ),
          ),
      ],
    );
  }

  /// 드래그 타겟 래퍼
  Widget _buildDragTarget(
    BuildContext context,
    WidgetRef ref, {
    required Widget child,
  }) {
    return DragTarget<TodoRead>(
      onWillAcceptWithDetails: (details) {
        final draggedTodo = details.data;
        // 자신 위에는 드롭 불가
        if (draggedTodo.id == node.todo.id) return false;
        // 순환 검사
        return canDropOn(tree, draggedTodo.id, node.todo.id);
      },
      onAcceptWithDetails: (details) async {
        final draggedTodo = details.data;
        // 부모 변경 API 호출
        await updateTodoMutation.run(
          ref,
          (tsx) => tsx
              .get(todoMutationsProvider.notifier)
              .changeParent(draggedTodo.id, node.todo.id),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isValidTarget = candidateData.isNotEmpty;
        final isInvalidTarget = rejectedData.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            border: isValidTarget
                ? Border.all(color: kDropTargetColor, width: 2)
                : isInvalidTarget
                ? Border.all(color: kInvalidDropColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
    );
  }

  /// 드래그 가능한 래퍼
  Widget _buildDraggable(
    BuildContext context,
    WidgetRef ref, {
    required Widget child,
  }) {
    return LongPressDraggable<TodoRead>(
      data: node.todo,
      delay: const Duration(milliseconds: 200),
      hapticFeedbackOnStart: true,
      onDragStarted: () {
        ref.read(draggingTodoIdProvider.notifier).setDragging(node.todo.id);
      },
      onDragEnd: (details) {
        ref.read(draggingTodoIdProvider.notifier).clear();
      },
      onDraggableCanceled: (velocity, offset) {
        ref.read(draggingTodoIdProvider.notifier).clear();
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            node.todo.title,
            style: Theme.of(context).textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: kDraggingOpacity, child: child),
      child: child,
    );
  }

  /// 타일 내용 빌드
  Widget _buildTileContent(
    BuildContext context,
    WidgetRef ref, {
    required TodoRead todo,
    required int depth,
    required bool hasChildren,
    required bool isExpanded,
    required bool isSelected,
    required bool isDragging,
  }) {
    final timerLinkable = canLinkTimer(todo);

    return InkWell(
      onTap: () {
        // 선택 처리
        ref.read(selectedTodoIdProvider.notifier).select(todo.id);
        onTap?.call(todo);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withAlpha(77)
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          // 깊이에 비례하는 들여쓰기
          padding: EdgeInsets.only(
            left: depth * kIndentWidth,
            right: 8,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              // 확장/축소 버튼
              if (hasChildren)
                _buildExpandButton(context, ref, isExpanded, todo.id)
              else
                const SizedBox(width: 24), // 정렬용 공간
              // 상태 선택기 (기존 체크박스 대체)
              TodoStatusSelector(todo: todo),

              const SizedBox(width: 8),

              // 제목
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: _getTextDecoration(todo.status),
                        color: _getTextColor(context, todo.status),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (todo.description != null &&
                        todo.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          todo.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // 좁은 화면에서도 넘치지 않게 제목 아래에 두고 자리가 모자라면 줄을 바꾼다
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // 진행 중인 타이머의 남은 시간
                        if (timerLinkable) _TodoTimerChip(todoId: todo.id),

                        // 누적 집중 시간
                        _TodoElapsedBadge(node: node),

                        // 태그 표시
                        if (todo.tags.isNotEmpty)
                          _buildTagIndicators(context, todo),

                        // 자식 개수 표시
                        if (hasChildren)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${node.children.length}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 액션 버튼들
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 타이머 시작 버튼
                  if (timerLinkable) _TodoTimerStartButton(todo: todo),

                  // 수정 버튼
                  OutlinedButton.icon(
                    onPressed: () =>
                        TodoActions.showEditTodoDialog(context, todo),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('수정'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 삭제 버튼
                  OutlinedButton.icon(
                    onPressed: () => TodoActions.showDeleteTodoDialog(
                      context,
                      ref,
                      todo,
                      node,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('삭제'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 확장/축소 버튼
  Widget _buildExpandButton(
    BuildContext context,
    WidgetRef ref,
    bool isExpanded,
    String todoId,
  ) {
    return GestureDetector(
      onTap: () {
        if (onToggleExpand != null) {
          onToggleExpand!(todoId);
        } else {
          // 기본 동작: expandedTodoIdsProvider 업데이트
          ref.read(expandedTodoIdsProvider.notifier).toggle(todoId);
        }
      },
      child: AnimatedRotation(
        turns: isExpanded ? 0.25 : 0, // 90도 회전
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.chevron_right, size: 24),
      ),
    );
  }

  /// 태그 인디케이터
  Widget _buildTagIndicators(BuildContext context, TodoRead todo) {
    final tags = todo.tags.toList();
    if (tags.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final displayCount = tags.length > 2 ? 2 : tags.length;

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 태그 색상 점들
          ...tags
              .take(displayCount)
              .map(
                (tag) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Tooltip(
                    message: tag.name,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: HexColor.fromHex(tag.color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.3,
                          ),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

          // 첫 번째 태그 이름 (공간이 있을 때)
          if (tags.isNotEmpty)
            Flexible(
              child: Text(
                tags.first.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // 추가 태그 개수 표시
          if (tags.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                '+${tags.length - 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 상태에 따른 텍스트 장식
  TextDecoration? _getTextDecoration(TodoStatus status) {
    switch (status) {
      case TodoStatus.done:
        return TextDecoration.lineThrough;
      case TodoStatus.cancelled:
        return TextDecoration.lineThrough;
      default:
        return null;
    }
  }

  /// 상태에 따른 텍스트 색상
  Color? _getTextColor(BuildContext context, TodoStatus status) {
    switch (status) {
      case TodoStatus.done:
        return Theme.of(context).colorScheme.onSurface.withAlpha(128);
      case TodoStatus.cancelled:
        return Theme.of(context).colorScheme.error.withAlpha(128);
      default:
        return null;
    }
  }
}

/// Todo의 누적 집중 시간 배지 (하위 Todo 포함)
///
/// 끝난 타이머 시간([todoTimerAggregationProvider])에 활성 타이머의 표시 경과 시간
/// ([activeTimerStreamProvider])을 더해 1초마다 갱신한다. 시간이 없으면 표시하지 않는다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_elapsed_test.dart
class _TodoElapsedBadge extends ConsumerWidget {
  final TodoTreeNode node;

  const _TodoElapsedBadge({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final finished =
        ref
            .watch(todoTimerAggregationProvider(node.id))
            .value
            ?.totalElapsedSeconds ??
        0;

    final subtreeIds = <String>{};
    void collect(TodoTreeNode current) {
      subtreeIds.add(current.id);
      for (final child in current.children) {
        collect(child);
      }
    }

    collect(node);

    // 하위 Todo까지의 활성 타이머 경과 시간 합. 활성 타이머가 없으면 null
    final active = ref.watch(
      activeTimerStreamProvider.select((states) {
        final seconds = <int>[
          for (final MapEntry(:key, :value) in (states.value ?? {}).entries)
            if (subtreeIds.contains(key)) value.elapsedSeconds,
        ];
        return seconds.isEmpty ? null : seconds.reduce((a, b) => a + b);
      }),
    );

    if (finished == 0 && active == null) return const SizedBox.shrink();

    final isActive = active != null;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          formatDuration(Duration(seconds: finished + (active ?? 0))),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 남은 시간을 mm:ss로, 한 시간 이상이면 h:mm:ss로 쓴다
String _formatRemaining(Duration remaining) {
  final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = remaining.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// Todo에 연결된 활성(RUNNING·PAUSED) 타이머의 남은 시간 칩. 누르면 타이머 화면으로 간다
///
/// [activeTimerStreamProvider]로 1초마다 갱신하고, 남은 시간이 0이면 에러 색이다. 활성 타이머가 없으면 표시하지 않는다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_timer_test.dart
class _TodoTimerChip extends ConsumerWidget {
  final String todoId;

  const _TodoTimerChip({required this.todoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(
      activeTimerStreamProvider.select(
        (states) => states.value?[todoId]?.remainingSeconds,
      ),
    );
    if (remaining == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = remaining == 0
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 8),
      child: ActionChip(
        avatar: Icon(Icons.timer_outlined, color: color),
        label: Text(_formatRemaining(Duration(seconds: remaining))),
        labelStyle: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
        tooltip: '타이머로 이동',
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onPressed: () => context.go(AppRoute.timer.path),
      ),
    );
  }
}

/// [todo]를 연결해 새 타이머를 시작하는 버튼. Todo에 활성 타이머가 있으면 표시하지 않는다
///
/// 새 작업 시작 다이얼로그를 [todo]를 고른 채 열고, 시작해도 할 일 화면에 머문다.
/// 시작하면 떠 있던 알림을 닫고 '타이머 보기'(타이머 화면으로 이동)가 있는 알림을 띄운다.
/// 실패하면 알린다. 다이얼로그에서 할 일을 여럿 고르면 할 일마다 시작하고, 시작하지 못한 할 일만 알린다.
/// 새 타이머를 시작하는 동안에는 누를 수 없다.
///
/// 테스트: test/features/todo/presentation/widgets/todo_tree_tile_timer_test.dart
class _TodoTimerStartButton extends ConsumerWidget {
  final TodoRead todo;

  const _TodoTimerStartButton({required this.todo});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final input = await showStartTimerDialog(
      context,
      initialDuration: defaultFocusDuration,
      initialTodo: todo,
    );
    if (input == null || !context.mounted) return;
    final controller = ref.read(timerControllerProvider.notifier);
    var failed = const <TodoRead>[];
    Object? error;
    if (input.todos.length >= 2) {
      failed = await controller.startTimers(
        todos: input.todos,
        duration: input.duration,
      );
    } else {
      try {
        await controller.startTimer(
          relatedTodoId: input.todos.firstOrNull?.id,
          title: input.title,
          allocatedDurationSeconds: input.duration.inSeconds,
        );
      } catch (e) {
        error = e;
      }
    }
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (error != null || failed.isNotEmpty) {
      messenger.showAppSnackBar(
        error != null ? '타이머 시작 실패: $error' : startFailureMessage(failed),
        kind: AppNoticeKind.error,
      );
      return;
    }
    // 알림이 떠 있는 사이 타일이 목록에서 빠져도 이동할 수 있게 라우터를 잡아 둔다
    final router = GoRouter.of(context);
    messenger.showAppSnackBar(
      '타이머를 시작했습니다',
      actionLabel: '타이머 보기',
      onAction: () => router.go(AppRoute.timer.path),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      activeTimerStreamProvider.select(
        (states) => states.value?.containsKey(todo.id) ?? false,
      ),
    );
    // 시작 요청이 끝날 때까지 컨트롤러(autoDispose)를 붙잡아 둔다
    final starting = ref.watch(
      timerControllerProvider.select((state) => state.isLoading),
    );
    if (active) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.play_circle_outline),
      tooltip: '타이머 시작',
      visualDensity: VisualDensity.compact,
      onPressed: starting ? null : () => _start(context, ref),
    );
  }
}

/// 루트 드롭 타겟 (루트로 이동)
///
/// 트리 상단에 배치하여 할 일을 루트 레벨로 이동할 수 있게 합니다.
class TodoRootDropTarget extends ConsumerWidget {
  const TodoRootDropTarget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<TodoRead>(
      onWillAcceptWithDetails: (details) {
        // 이미 루트인 경우 드롭 불필요
        return details.data.parentId != null;
      },
      onAcceptWithDetails: (details) async {
        final draggedTodo = details.data;
        // 부모를 null로 설정하여 루트로 이동
        await updateTodoMutation.run(
          ref,
          (tsx) => tsx
              .get(todoMutationsProvider.notifier)
              .changeParent(draggedTodo.id, null),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isValidTarget = candidateData.isNotEmpty;
        final theme = Theme.of(context);

        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isValidTarget
                  ? kDropTargetColor
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: isValidTarget ? 2 : 1,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isValidTarget
                ? kDropTargetColor.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: 16,
                  color: isValidTarget
                      ? kDropTargetColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '루트로 이동',
                  style: TextStyle(
                    color: isValidTarget
                        ? kDropTargetColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isValidTarget
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
