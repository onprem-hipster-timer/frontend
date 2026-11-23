import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_child_count_badge.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tag_indicators.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_tree/todo_tree_tile_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _statuses = {
  '미예정': TodoStatus.unscheduled,
  '예정됨': TodoStatus.scheduled,
  '완료': TodoStatus.done,
  '취소': TodoStatus.cancelled,
};

@widgetbook.UseCase(name: '할 일 줄', type: TodoTreeTileView, path: '[할 일]')
Widget todoTreeTileView(BuildContext context) {
  final knobs = context.knobs;
  final place = knobs.object.dropdown(
    label: '쓰이는 곳',
    description: '할 일 목록에서는 펼침 표시·태그·하위 개수를, 일정에 연결할 할 일 고르기에서는 체크 상자를 둔다',
    options: const ['할 일 목록', '할 일 고르기'],
  );
  final picker = place == '할 일 고르기';
  final status = knobs.object.dropdown(
    label: '상태',
    description: '완료·취소는 제목에 취소선을 긋는다',
    options: _statuses.keys.toList(),
  );
  final depth = knobs.int.slider(
    label: '깊이',
    description: '하위 할 일일수록 한 단계에 24씩 들여 쓴다',
    initialValue: 1,
    min: 0,
    max: 5,
  );
  final long = knobs.boolean(label: '긴 제목');
  final description = knobs.boolean(label: '설명', initialValue: true);
  final tagCount = knobs.int.slider(
    label: '태그 수',
    initialValue: 2,
    min: 0,
    max: 5,
  );
  final children = knobs.int.slider(
    label: '하위 할 일 수',
    description: '0이면 펼침 표시와 개수 배지가 없다',
    initialValue: 3,
    min: 0,
    max: 40,
  );
  final selected = knobs.boolean(
    label: '선택됨',
    description: '할 일 목록에서는 누른 줄, 고르기에서는 체크한 줄',
  );
  final todo = TodoRead(
    id: 'todo-1',
    title: long
        ? '중간 발표 자료 만들기: 지난 회의에서 나온 의견 반영하고 시연 영상까지 다시 찍기'
        : '중간 발표 자료 만들기',
    todoGroupId: 'todo-group-1',
    status: _statuses[status]!,
    createdAt: planStamp,
    tags: planTags.take(tagCount).toList(),
    description: description ? '모모와 역할 나누기, 금요일까지 초안' : null,
    deadline: DateTime(2026, 3, 13),
  );
  // 앱의 펼침 버튼은 할 일 목록 줄 안에 숨은 위젯이라 같은 모양의 화살표로 둔다
  final leading = picker
      ? Checkbox(value: selected, onChanged: (_) {})
      : children > 0
      ? const Icon(Icons.chevron_right, size: 24)
      : null;
  return ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      TodoTreeTileView(
        todo: todo,
        depth: depth,
        leading: leading,
        meta: [
          if (!picker && todo.tags.isNotEmpty)
            TodoTagIndicators(tags: todo.tags),
          if (!picker && children > 0) TodoChildCountBadge(count: children),
        ],
        selected: selected,
        onTap: () {},
      ),
    ],
  );
}
