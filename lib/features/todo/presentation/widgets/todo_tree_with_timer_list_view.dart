import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/providers/timer_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree_tile_with_timer.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';

/// 타이머 기능이 통합된 Todo Tree ListView
///
/// Todo 계층 구조를 ExpansionTile 형태로 표시하며,
/// 각 Todo에 타이머 기능(재생/정지, 시간 표시)이 포함됩니다.
class TodoTreeWithTimerListView extends ConsumerStatefulWidget {
  final String? groupId;

  const TodoTreeWithTimerListView({super.key, this.groupId});

  @override
  ConsumerState<TodoTreeWithTimerListView> createState() =>
      _TodoTreeWithTimerListViewState();
}

class _TodoTreeWithTimerListViewState
    extends ConsumerState<TodoTreeWithTimerListView> {
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final todoTreeAsync = ref.watch(todoTreeProvider(widget.groupId));

    return todoTreeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Todo를 불러올 수 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(todoTreeProvider(widget.groupId)),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (todoTree) {
        if (todoTree.totalCount == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.checklist,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text('Todo가 없습니다'),
                const Text('새로운 Todo를 추가해보세요'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: _getVisibleNodeCount(todoTree),
          itemBuilder: (context, index) {
            final node = _getVisibleNodeAt(todoTree, index);
            if (node == null) return const SizedBox();

            return TodoTreeTileWithTimer(
              node: node,
              isExpanded: _expandedIds.contains(node.id),
              onTap: () => _handleNodeTap(node),
              onExpand: node.hasChildren
                  ? () => _toggleExpansion(node.id)
                  : null,
            );
          },
        );
      },
    );
  }

  /// 노드 탭 핸들러
  void _handleNodeTap(TodoTreeNode node) {
    // TODO: Todo 상세 보기 또는 편집 화면으로 이동
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Todo 탭: ${node.todo.title}')));
  }

  /// 확장/축소 토글
  void _toggleExpansion(String nodeId) {
    setState(() {
      if (_expandedIds.contains(nodeId)) {
        _expandedIds.remove(nodeId);
      } else {
        _expandedIds.add(nodeId);
      }
    });
  }

  /// 표시할 노드 개수 계산
  int _getVisibleNodeCount(TodoTree tree) {
    int count = 0;

    void countVisibleNodes(List<TodoTreeNode> nodes) {
      for (final node in nodes) {
        count++;
        if (_expandedIds.contains(node.id) && node.hasChildren) {
          countVisibleNodes(node.children);
        }
      }
    }

    countVisibleNodes(tree.roots);
    return count;
  }

  /// 인덱스에 해당하는 표시 가능한 노드 반환
  TodoTreeNode? _getVisibleNodeAt(TodoTree tree, int targetIndex) {
    int currentIndex = 0;

    TodoTreeNode? findNodeAtIndex(List<TodoTreeNode> nodes) {
      for (final node in nodes) {
        if (currentIndex == targetIndex) {
          return node;
        }
        currentIndex++;

        if (_expandedIds.contains(node.id) && node.hasChildren) {
          final result = findNodeAtIndex(node.children);
          if (result != null) return result;
        }
      }
      return null;
    }

    return findNodeAtIndex(tree.roots);
  }
}

/// Todo와 타이머 기능을 모두 표시하는 통합 페이지
class TodoWithTimerPage extends ConsumerWidget {
  const TodoWithTimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo & Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allTodoTreeProvider);
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          // 활성 타이머 상태 표시 (상단 고정)
          ActiveTimerStatusBar(),

          // Todo Tree with Timer (메인 컨텐츠)
          Expanded(child: TodoTreeWithTimerListView()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Todo 생성 화면으로 이동
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Todo 생성 기능이 곧 구현됩니다')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 활성 타이머 상태를 표시하는 상단 바
class ActiveTimerStatusBar extends ConsumerWidget {
  const ActiveTimerStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTimersAsync = ref.watch(activeTimerStreamProvider);

    return activeTimersAsync.when(
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
      data: (activeStates) {
        if (activeStates.isEmpty) {
          return const SizedBox();
        }

        final runningTimers = activeStates.values
            .where((state) => state.isRunning)
            .toList();

        if (runningTimers.isEmpty) {
          return const SizedBox();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '활성 타이머: ${runningTimers.length}개',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (runningTimers.length == 1)
                Text(
                  runningTimers.first.formattedTime,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
