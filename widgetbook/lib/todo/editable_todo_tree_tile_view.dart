import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet.dart'
    show canLinkTimer;
import 'package:momeet/features/todo/presentation/utils/todo_tree_builder.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_status_selector_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/editable_todo_tree_tile_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_child_count_badge.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_elapsed_badge_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tag_indicators.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_chip_view.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_timer_start_button_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// 타이머가 도는 할 일
const _runningId = 'todo-1';

/// 할 일마다 끝난 타이머 시간(초). 배지는 하위까지 더해 보인다
const _finishedSeconds = {
  'todo-1': 3600,
  'todo-2': 1500,
  'todo-3': 2700,
  'todo-4': 900,
};

@widgetbook.UseCase(
  name: '할 일 목록 줄',
  type: EditableTodoTreeTileView,
  path: '[할 일]',
)
Widget editableTodoTreeTileView(BuildContext context) {
  final knobs = context.knobs;
  final long = knobs.boolean(label: '긴 제목');
  final running = knobs.boolean(
    label: '타이머 도는 중',
    initialValue: true,
    description: '맨 위 할 일로 시작한 타이머가 돌면 남은 시간 칩을 두고 타이머 시작 버튼을 숨긴다',
  );
  final starting = knobs.boolean(
    label: '시작하는 중',
    description: '새 타이머를 시작하는 동안 타이머 시작 버튼을 누를 수 없다',
  );
  // 앱에서는 할 일 목록 화면에 맨 위 할 일부터 하위를 들여 쓰며 이어 놓인다.
  // 화살표로 펼치고 접고, 누르면 고르고, 길게 눌러 다른 줄 위에 놓으면 그 하위로 옮긴다
  return ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [_Tree(long: long, running: running, starting: starting)],
  );
}

/// 펼침·고른 줄·고른 상태·옮긴 위치를 들고 있어 앱처럼 반응한다
class _Tree extends StatefulWidget {
  const _Tree({
    required this.long,
    required this.running,
    required this.starting,
  });

  final bool long;
  final bool running;
  final bool starting;

  @override
  State<_Tree> createState() => _TreeState();
}

class _TreeState extends State<_Tree> {
  final _expanded = {'todo-1', 'todo-3'};
  String? _selectedId;
  final _statuses = <String, TodoStatus>{};
  final _parents = <String, String?>{};

  TodoRead _todo(
    String id,
    String title, {
    String? parentId,
    TodoStatus status = TodoStatus.unscheduled,
    List<TagRead> tags = const [],
    String? description,
  }) => TodoRead(
    id: id,
    title: title,
    todoGroupId: 'todo-group-1',
    parentId: _parents.containsKey(id) ? _parents[id] : parentId,
    status: _statuses[id] ?? status,
    createdAt: planStamp,
    tags: tags,
    description: description,
  );

  @override
  Widget build(BuildContext context) {
    final tree = buildTodoTree([
      _todo(
        'todo-1',
        widget.long
            ? '중간 발표 자료 만들기: 지난 회의에서 나온 의견 반영하고 시연 영상까지 다시 찍기'
            : '중간 발표 자료 만들기',
        status: TodoStatus.scheduled,
        tags: planTags.take(2).toList(),
        description: '모모와 역할 나누기, 금요일까지 초안',
      ),
      _todo('todo-2', '슬라이드 초안 쓰기', parentId: 'todo-1'),
      _todo(
        'todo-3',
        '시연 영상 찍기',
        parentId: 'todo-1',
        status: TodoStatus.scheduled,
      ),
      _todo('todo-4', '자막 넣기', parentId: 'todo-3', status: TodoStatus.done),
    ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final root in tree.roots)
          _Tile(
            node: root,
            tree: tree,
            expanded: _expanded,
            selectedId: _selectedId,
            running: widget.running,
            starting: widget.starting,
            onToggle: (id) => setState(
              () => _expanded.contains(id)
                  ? _expanded.remove(id)
                  : _expanded.add(id),
            ),
            onSelect: (id) => setState(() => _selectedId = id),
            onStatus: (id, status) => setState(() => _statuses[id] = status),
            onMove: (id, parentId) => setState(() => _parents[id] = parentId),
          ),
      ],
    );
  }
}

/// [node] 줄과 펼친 하위 줄들
class _Tile extends StatelessWidget {
  const _Tile({
    required this.node,
    required this.tree,
    required this.expanded,
    required this.selectedId,
    required this.running,
    required this.starting,
    required this.onToggle,
    required this.onSelect,
    required this.onStatus,
    required this.onMove,
  });

  final TodoTreeNode node;
  final TodoTree tree;
  final Set<String> expanded;
  final String? selectedId;
  final bool running;
  final bool starting;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onSelect;
  final void Function(String id, TodoStatus status) onStatus;
  final void Function(String id, String parentId) onMove;

  @override
  Widget build(BuildContext context) {
    final todo = node.todo;
    final open = expanded.contains(todo.id);
    final linkable = canLinkTimer(todo);
    final timerHere = running && todo.id == _runningId;
    final subtree = _subtree(node);
    return EditableTodoTreeTileView(
      todo: todo,
      depth: node.depth,
      expanded: open,
      onToggleExpand: node.hasChildren ? () => onToggle(todo.id) : null,
      status: TodoStatusSelectorView(
        status: todo.status,
        onSelected: (status) => onStatus(todo.id, status),
      ),
      meta: [
        if (linkable && timerHere)
          const TodoTimerChipView(remainingSeconds: 754),
        TodoElapsedBadgeView(
          finishedSeconds: subtree.fold(
            0,
            (sum, id) => sum + (_finishedSeconds[id] ?? 0),
          ),
          activeSeconds: running && subtree.contains(_runningId) ? 746 : null,
        ),
        if (todo.tags.isNotEmpty) TodoTagIndicators(tags: todo.tags),
        if (node.hasChildren) TodoChildCountBadge(count: node.children.length),
      ],
      // 타이머가 돌고 있는 할 일은 버튼 자리를 두되 버튼을 그리지 않는다
      timerButton: !linkable
          ? null
          : timerHere
          ? const SizedBox.shrink()
          : TodoTimerStartButtonView(starting: starting, onPressed: () {}),
      onEdit: () {},
      onDelete: () {},
      selected: selectedId == todo.id,
      onTap: () => onSelect(todo.id),
      canAccept: (dragged) =>
          dragged.id != todo.id && canDropOn(tree, dragged.id, todo.id),
      onAccept: (dragged) => onMove(dragged.id, todo.id),
      onDragStarted: () {},
      onDragEnd: () {},
      children: [
        if (node.hasChildren && open)
          for (final child in node.children)
            _Tile(
              node: child,
              tree: tree,
              expanded: expanded,
              selectedId: selectedId,
              running: running,
              starting: starting,
              onToggle: onToggle,
              onSelect: onSelect,
              onStatus: onStatus,
              onMove: onMove,
            ),
      ],
    );
  }
}

/// [node]와 그 하위 모든 할 일의 id
Set<String> _subtree(TodoTreeNode node) => {
  node.id,
  for (final child in node.children) ..._subtree(child),
};
