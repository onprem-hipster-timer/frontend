// Todo 목록 페이지
//
// 계층형 할 일 트리를 표시하고 드래그 앤 드롭 기능을 제공합니다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tree_tile.dart';
import '../widgets/todo_form_sheet.dart';

/// Todo 목록 페이지
class TodoListPage extends ConsumerWidget {
  /// 필터링할 그룹 ID (선택사항)
  final String? groupId;

  const TodoListPage({
    super.key,
    this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoTreeAsync = ref.watch(todoTreeProvider(groupId));
    final mutationState = ref.watch(todoMutationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일'),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(todosProvider);
            },
          ),
          // 모두 접기/펴기 버튼
          IconButton(
            icon: const Icon(Icons.unfold_more),
            tooltip: '모두 펴기',
            onPressed: () => _expandAll(ref, todoTreeAsync),
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            tooltip: '모두 접기',
            onPressed: () => _collapseAll(ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          todoTreeAsync.when(
            data: (tree) => _buildTreeView(context, ref, tree),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '오류가 발생했습니다',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(todosProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),

          // 로딩 오버레이 (뮤테이션 중)
          if (mutationState.isLoading)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTodoDialog(context, ref),
        tooltip: '새 할 일',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 트리 뷰 빌드
  Widget _buildTreeView(BuildContext context, WidgetRef ref, tree) {
    if (tree.roots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '할 일이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새 할 일을 추가하세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(todosProvider);
        await ref.read(todosProvider(groupId).future);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 루트로 드롭하기 위한 타겟
          const TodoRootDropTarget(),

          // 트리 노드들
          ...tree.roots.map((node) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TodoTreeTile(
              node: node,
              tree: tree,
              onTap: (todo) => _showTodoDetail(context, todo),
            ),
          )),

          // 하단 여백 (FAB 가리지 않도록)
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 모두 펴기
  void _expandAll(WidgetRef ref, AsyncValue<dynamic> treeAsync) {
    treeAsync.whenData((tree) {
      final allIds = tree.flatOrder.toSet().cast<String>();
      ref.read(expandedTodoIdsProvider.notifier).addAll(allIds);
    });
  }

  /// 모두 접기
  void _collapseAll(WidgetRef ref) {
    ref.read(expandedTodoIdsProvider.notifier).clear();
  }

  /// 할 일 상세 보기/수정
  void _showTodoDetail(BuildContext context, TodoRead todo) {
    showTodoFormSheet(
      context,
      todo: todo, // 수정 모드로 전달
    );
  }

  /// 할 일 생성 다이얼로그
  void _showCreateTodoDialog(BuildContext context, WidgetRef ref) {
    showTodoFormSheet(
      context,
      defaultTagGroupId: groupId,
    );
  }
}


