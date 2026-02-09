// Todo 목록 페이지
//
// 계층형 할 일 트리를 표시하고 드래그 앤 드롭 기능을 제공합니다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tree_tile.dart';

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

  /// 할 일 상세 보기
  void _showTodoDetail(BuildContext context, TodoRead todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => TodoDetailSheet(
          todo: todo,
          scrollController: scrollController,
        ),
      ),
    );
  }

  /// 할 일 생성 다이얼로그
  void _showCreateTodoDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateTodoDialog(groupId: groupId),
    );
  }
}

/// Todo 상세 시트
class TodoDetailSheet extends ConsumerStatefulWidget {
  final TodoRead todo;
  final ScrollController scrollController;

  const TodoDetailSheet({
    super.key,
    required this.todo,
    required this.scrollController,
  });

  @override
  ConsumerState<TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends ConsumerState<TodoDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // 헤더
          Row(
            children: [
              Expanded(
                child: Text(
                  '할 일 상세',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () => _deleteTodo(context),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // 제목
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '제목',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // 설명
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '설명',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // 상태
          DropdownButtonFormField<TodoStatus>(
            initialValue: widget.todo.status,
            decoration: const InputDecoration(
              labelText: '상태',
              border: OutlineInputBorder(),
            ),
            items: TodoStatus.values.map((status) => DropdownMenuItem(
              value: status,
              child: Text(_getStatusLabel(status)),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                _updateStatus(value);
              }
            },
          ),
          const SizedBox(height: 24),

          // 저장 버튼
          FilledButton(
            onPressed: _saveChanges,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(TodoStatus status) {
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

  Future<void> _saveChanges() async {
    final updateData = TodoUpdate(
      title: _titleController.text,
      description: _descriptionController.text,
    );

    await ref.read(todoMutationsProvider.notifier).update(
      widget.todo.id,
      updateData,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장되었습니다')),
      );
    }
  }

  Future<void> _updateStatus(TodoStatus status) async {
    await ref.read(todoMutationsProvider.notifier).changeStatus(
      widget.todo.id,
      status,
    );
  }

  Future<void> _deleteTodo(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 삭제'),
        content: const Text('이 할 일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(todoMutationsProvider.notifier).delete(widget.todo.id);
      if (mounted) {
        if (!context.mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다')),
        );
      }
    }
  }
}

/// Todo 생성 다이얼로그
class CreateTodoDialog extends ConsumerStatefulWidget {
  final String? groupId;

  const CreateTodoDialog({super.key, this.groupId});

  @override
  ConsumerState<CreateTodoDialog> createState() => _CreateTodoDialogState();
}

class _CreateTodoDialogState extends ConsumerState<CreateTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 할 일'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '제목을 입력하세요';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _createTodo,
          child: const Text('생성'),
        ),
      ],
    );
  }

  Future<void> _createTodo() async {
    if (!_formKey.currentState!.validate()) return;

    // 그룹 ID가 없으면 기본값 사용 (실제 구현에서는 선택 UI 추가 필요)
    final groupId = _selectedGroupId ?? '00000000-0000-0000-0000-000000000000';

    final createData = TodoCreate(
      title: _titleController.text,
      tagGroupId: groupId,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    await ref.read(todoMutationsProvider.notifier).create(createData);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할 일이 생성되었습니다')),
      );
    }
  }
}
