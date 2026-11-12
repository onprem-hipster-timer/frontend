import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일을 고르는 화면을 연다. 고르지 않고 닫으면 null.
///
/// [selectable]인 할 일만 그룹별 트리로 보이고, [selected]를 체크한 채 연다.
/// 한 줄을 누르면 그 할 일 하나를, '연결 안 함'은 빈 목록을 돌려준다.
/// 둘 이상 체크하면 나오는 'N개 선택 완료'는 체크한 차례대로 돌려준다.
///
/// 테스트: test/features/todo/presentation/pages/todo_picker_page_test.dart
Future<List<TodoRead>?> showTodoPicker(
  BuildContext context, {
  required bool Function(TodoRead todo) selectable,
  List<TodoRead> selected = const [],
}) => Navigator.of(context, rootNavigator: true).push<List<TodoRead>>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => TodoPickerPage(selectable: selectable, selected: selected),
  ),
);

/// 할 일 고르기 화면. [showTodoPicker]로 연다.
class TodoPickerPage extends ConsumerStatefulWidget {
  const TodoPickerPage({
    super.key,
    required this.selectable,
    this.selected = const [],
  });

  final bool Function(TodoRead todo) selectable;
  final List<TodoRead> selected;

  @override
  ConsumerState<TodoPickerPage> createState() => _TodoPickerPageState();
}

class _TodoPickerPageState extends ConsumerState<TodoPickerPage> {
  final _query = TextEditingController();

  /// 체크한 할 일. 체크한 차례대로
  late final _checked = [...widget.selected];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _isChecked(TodoRead todo) => _checked.any((it) => it.id == todo.id);

  void _toggle(TodoRead todo) => setState(() {
    if (_isChecked(todo)) {
      _checked.removeWhere((it) => it.id == todo.id);
    } else {
      _checked.add(todo);
    }
  });

  void _pick(List<TodoRead> todos) => Navigator.of(context).pop(todos);

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(allTodosProvider);
    final groups = ref.watch(todoGroupsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('${Terms.todo} 고르기')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(
                hintText: '제목으로 찾기',
                hintMaxLines: 2,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: todos.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                title: '${Terms.todo.withJosa('을', '를')} 불러오지 못했습니다',
                error: error,
                onRetry: () => ref.invalidate(todosProvider),
              ),
              data: (todos) => _PickerList(
                sections: _sections(
                  todos.where(widget.selectable).toList(),
                  groups,
                  _query.text.trim().toLowerCase(),
                ),
                noneSelected: _checked.isEmpty,
                isChecked: _isChecked,
                onToggle: _toggle,
                onPick: _pick,
              ),
            ),
          ),
        ],
      ),
      // 하나는 그 할 일을 눌러 고르므로 둘 이상 체크했을 때만 둔다
      bottomNavigationBar: _checked.length < 2
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: () => _pick([..._checked]),
                  child: Text('${_checked.length}개 선택 완료'),
                ),
              ),
            ),
    );
  }
}

/// 그룹 하나와 그 안에서 보일 줄들
typedef _Section = ({String title, List<TodoTreeNode> rows});

/// 할 일 그룹 순서대로 묶고, [query]가 있으면 제목이 맞는 할 일과 그 상위만 남긴다.
/// 그룹 목록에 없는 그룹의 할 일은 끝에 '기타' 하나로 묶는다.
List<_Section> _sections(
  List<TodoRead> todos,
  List<TodoGroupRead> groups,
  String query,
) {
  final known = {for (final group in groups) group.id};
  _Section section(String title, bool Function(TodoRead) inGroup) => (
    title: title,
    rows: _rows(buildTodoTree(todos.where(inGroup).toList()), query),
  );
  return [
    for (final group in groups)
      section(group.name, (todo) => todo.todoGroupId == group.id),
    section('기타', (todo) => !known.contains(todo.todoGroupId)),
  ].where((section) => section.rows.isNotEmpty).toList();
}

/// 트리를 위에서부터 차례로 펼친 줄. [query]가 있으면 맞는 줄과 그 상위만
List<TodoTreeNode> _rows(TodoTree tree, String query) {
  bool matches(TodoTreeNode node) =>
      node.todo.title.toLowerCase().contains(query) ||
      node.children.any(matches);
  final rows = <TodoTreeNode>[];
  void visit(TodoTreeNode node) {
    if (query.isNotEmpty && !matches(node)) return;
    rows.add(node);
    node.children.forEach(visit);
  }

  tree.roots.forEach(visit);
  return rows;
}

class _PickerList extends StatelessWidget {
  const _PickerList({
    required this.sections,
    required this.noneSelected,
    required this.isChecked,
    required this.onToggle,
    required this.onPick,
  });

  final List<_Section> sections;
  final bool noneSelected;
  final bool Function(TodoRead todo) isChecked;
  final void Function(TodoRead todo) onToggle;
  final void Function(List<TodoRead> todos) onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        ListTile(
          leading: const Icon(Icons.link_off),
          title: const Text('연결 안 함'),
          selected: noneSelected,
          onTap: () => onPick(const []),
        ),
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: AppSectionHeader(section.title),
          ),
          for (final node in section.rows)
            TodoTreeTileView(
              todo: node.todo,
              depth: node.depth,
              leading: Checkbox(
                value: isChecked(node.todo),
                semanticLabel: '${node.todo.title} 고르기',
                onChanged: (_) => onToggle(node.todo),
              ),
              selected: isChecked(node.todo),
              onTap: () => onPick([node.todo]),
            ),
        ],
      ],
    );
  }
}
