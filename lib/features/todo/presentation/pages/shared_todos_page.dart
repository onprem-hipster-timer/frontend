import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/shared_todo_providers.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/features/visibility/presentation/widgets/shared_by_text.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 다른 사람이 공유한 할 일을 공유한 사람별로 묶어 보이는 화면. 보기만 한다
///
/// 공유된 할 일끼리 상위·하위면 트리로 잇고, 상위가 공유되지 않은 할 일은 맨 위에 둔다.
///
/// 테스트: test/features/todo/presentation/pages/shared_todos_page_test.dart
class SharedTodosPage extends ConsumerWidget {
  const SharedTodosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(sharedTodosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('공유받은 ${Terms.todo}')),
      body: todosAsync.when(
        data: (todos) => todos.isEmpty
            ? AppEmptyState(
                icon: Icons.people_outline,
                title: '공유받은 ${Terms.todo.withJosa('이', '가')} 없습니다',
              )
            : _OwnerSections(todos: todos),
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(
          title: '공유받은 ${Terms.todo.withJosa('을', '를')} 불러오지 못했습니다',
          error: error,
          onRetry: () => ref.invalidate(sharedTodosProvider),
        ),
      ),
    );
  }
}

/// 공유한 사람마다 이름과 그 사람의 할 일 트리
class _OwnerSections extends StatelessWidget {
  const _OwnerSections({required this.todos});

  final List<TodoRead> todos;

  @override
  Widget build(BuildContext context) {
    final byOwner = <String?, List<TodoRead>>{};
    for (final todo in todos) {
      byOwner.putIfAbsent(todo.ownerId, () => []).add(todo);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppHintCard(
          message: '공유받은 ${Terms.todo.withJosa('은', '는')} 보기만 할 수 있습니다',
          icon: Icons.visibility_outlined,
        ),
        for (final MapEntry(key: ownerId, value: owned) in byOwner.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: SharedByText(
              ownerId: ownerId,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final node in _flatten(buildTodoTree(owned).roots))
            TodoTreeTileView(todo: node.todo, depth: node.depth),
          const Divider(),
        ],
      ],
    );
  }
}

/// [roots]와 그 하위를 위에서부터 차례로 편다
Iterable<TodoTreeNode> _flatten(List<TodoTreeNode> roots) sync* {
  for (final node in roots) {
    yield node;
    yield* _flatten(node.children);
  }
}
