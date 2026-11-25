import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_group_field_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_todo.dart';

enum _Load { done, loading, failed }

@widgetbook.UseCase(name: '할 일 목록 칸', type: TodoGroupFieldView, path: '[할 일]')
Widget todoGroupFieldView(BuildContext context) {
  final knobs = context.knobs;
  final load = knobs.object.dropdown(
    label: '상태',
    description: '목록을 불러오는 동안은 누를 수 없고, 불러오지 못하면 칸 아래에 알린다',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
  );
  final picked = knobs.boolean(
    label: '목록을 고름',
    description: '고르지 않으면 기본 목록을 보이고, 새 할 일은 기본 목록에 들어간다',
  );
  final long = knobs.boolean(label: '긴 목록 이름');
  final locked = knobs.boolean(
    label: '바꿀 수 없음',
    description: '하위 할 일을 만들 때는 상위 할 일의 목록을 따른다',
  );
  final moving = knobs.boolean(
    label: '할 일 수정',
    description: '있는 할 일을 고칠 때는 고르는 창에 옮기면 함께 바뀌는 것을 알린다',
  );
  final groups = [...sampleTodoGroups, if (long) sampleLongTodoGroup];
  final AsyncValue<List<TodoGroupRead>> value = switch (load) {
    _Load.done => AsyncData(groups),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 할 일 입력 시트의 칸 여백. 노브를 바꾸면 고른 목록을 버리고 노브 값으로 돌아간다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: _GroupDemo(
      key: ValueKey((picked, long)),
      groups: value,
      initialId: picked ? groups.last.id : null,
      locked: locked,
      pickerContent: moving
          ? todoGroupMoveNote(
              TodoRead(
                id: 'todo-1',
                title: '중간 발표 자료 만들기',
                todoGroupId: groups.last.id,
                status: TodoStatus.unscheduled,
                createdAt: DateTime(2026, 2, 20, 9, 30),
              ),
            )
          : null,
    ),
  );
}

/// 고르는 창에서 고른 목록이 칸에 보이도록 고른 목록을 들고 있는다
class _GroupDemo extends StatefulWidget {
  const _GroupDemo({
    super.key,
    required this.groups,
    required this.initialId,
    required this.locked,
    required this.pickerContent,
  });

  final AsyncValue<List<TodoGroupRead>> groups;
  final String? initialId;
  final bool locked;
  final String? pickerContent;

  @override
  State<_GroupDemo> createState() => _GroupDemoState();
}

class _GroupDemoState extends State<_GroupDemo> {
  late String? _selectedId = widget.initialId;

  @override
  Widget build(BuildContext context) {
    return TodoGroupFieldView(
      groups: widget.groups,
      selectedId: _selectedId,
      onChanged: (id) => setState(() => _selectedId = id),
      locked: widget.locked,
      pickerContent: widget.pickerContent,
    );
  }
}
