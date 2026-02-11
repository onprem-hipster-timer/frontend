// 재귀적 Todo 트리 타일 위젯
//
// 계층형 할 일 트리의 각 노드를 렌더링합니다.
// 드래그 앤 드롭으로 부모 변경을 지원합니다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/core/utils/color_utils.dart';

import '../providers/todo_provider.dart';
import '../utils/todo_tree_builder.dart';

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
          ...node.children.map((childNode) => TodoTreeTile(
            node: childNode,
            tree: tree,
            onTap: onTap,
            onToggleExpand: onToggleExpand,
          )),
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
        await ref.read(todoMutationsProvider.notifier).changeParent(
          draggedTodo.id,
          node.todo.id,
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
      childWhenDragging: Opacity(
        opacity: kDraggingOpacity,
        child: child,
      ),
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

              // 체크박스 (상태 표시)
              _buildStatusCheckbox(context, ref, todo),

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
                    if (todo.description != null && todo.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          todo.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // 태그 표시
              if (todo.tags.isNotEmpty)
                _buildTagIndicators(context, todo),

              // 자식 개수 표시
              if (hasChildren)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        child: const Icon(
          Icons.chevron_right,
          size: 24,
        ),
      ),
    );
  }

  /// 상태 체크박스
  Widget _buildStatusCheckbox(
    BuildContext context,
    WidgetRef ref,
    TodoRead todo,
  ) {
    final isDone = todo.status == TodoStatus.done;
    final isCancelled = todo.status == TodoStatus.cancelled;

    return Checkbox(
      value: isDone,
      tristate: false,
      onChanged: (value) async {
        if (isCancelled) return; // 취소된 항목은 변경 불가

        final newStatus = value == true ? TodoStatus.done : TodoStatus.unscheduled;
        await ref.read(todoMutationsProvider.notifier).changeStatus(
          todo.id,
          newStatus,
        );
      },
    );
  }

  /// 태그 인디케이터
  Widget _buildTagIndicators(BuildContext context, TodoRead todo) {
    final tags = todo.tags.toList();
    if (tags.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final displayCount = tags.length > 2 ? 2 : tags.length;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 태그 색상 점들
          ...tags.take(displayCount).map((tag) => Padding(
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
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          )),

          // 첫 번째 태그 이름 (공간이 있을 때)
          if (tags.isNotEmpty)
            Text(
              tags.first.name,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        await ref.read(todoMutationsProvider.notifier).changeParent(
          draggedTodo.id,
          null,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isValidTarget = candidateData.isNotEmpty;

        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isValidTarget ? kDropTargetColor : Colors.grey.withAlpha(77),
              width: isValidTarget ? 2 : 1,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isValidTarget
                ? kDropTargetColor.withAlpha(26)
                : Colors.transparent,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: 16,
                  color: isValidTarget ? kDropTargetColor : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '루트로 이동',
                  style: TextStyle(
                    color: isValidTarget ? kDropTargetColor : Colors.grey,
                    fontWeight: isValidTarget ? FontWeight.bold : FontWeight.normal,
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
