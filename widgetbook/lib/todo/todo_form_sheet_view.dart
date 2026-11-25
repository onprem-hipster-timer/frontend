import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet_widgetbook/calendar/samples_plan.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';
import 'samples_todo.dart';

enum _Mode { create, child, edit }

enum _Load { done, loading, failed }

@widgetbook.UseCase(name: '할 일 입력 시트', type: TodoFormSheetView, path: '[할 일]')
Widget todoFormSheetView(BuildContext context) {
  final knobs = context.knobs;
  final mode = knobs.object.dropdown(
    label: '쓰이는 곳',
    description: '하위 할 일은 상위 할 일의 목록을 따르므로 목록 칸을 바꿀 수 없다',
    options: _Mode.values,
    labelBuilder: (mode) => switch (mode) {
      _Mode.create => '새 할 일 만들기',
      _Mode.child => '하위 할 일 만들기',
      _Mode.edit => '할 일 수정',
    },
  );
  final load = knobs.object.dropdown(
    label: '목록·태그 상태',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
  );
  final long = knobs.boolean(label: '긴 제목', description: '할 일 수정에서 채워 둔 제목');
  final busy = knobs.boolean(
    label: '저장 중',
    description: '생성·수정을 누른 뒤 끝날 때까지 버튼에 진행 표시를 둔다',
  );
  final todo = mode == _Mode.edit
      ? TodoRead(
          id: 'todo-1',
          title: long
              ? '중간 발표 자료 만들기: 지난 회의에서 나온 의견 반영하고 시연 영상까지 다시 찍기'
              : '중간 발표 자료 만들기',
          todoGroupId: 'todo-group-1',
          status: TodoStatus.scheduled,
          createdAt: planStamp,
          tags: [planTags[0], planTags[2]],
          description: '모모와 역할 나누기, 금요일까지 초안',
          deadline: DateTime(2026, 3, 13),
        )
      : null;
  final AsyncValue<List<TodoGroupRead>> todoGroups = switch (load) {
    _Load.done => AsyncData(sampleTodoGroups),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('연결 시간 초과'), StackTrace.empty),
  };
  final AsyncValue<List<TagGroupWithTags>> tagGroups = switch (load) {
    _Load.done => AsyncData(sampleTagGroups),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('연결 시간 초과'), StackTrace.empty),
  };
  // 앱에서는 할 일 목록 화면의 + 버튼이나 할 일 줄의 수정을 누르면 아래에서 올라온다.
  // 노브를 바꾸면 입력한 값을 버리고 처음부터 채운다
  return SheetPreview(
    child: TodoFormSheetView(
      key: ValueKey((mode, long)),
      todo: todo,
      defaultTodoGroupId: mode == _Mode.edit ? null : 'todo-group-1',
      groupLocked: mode == _Mode.child,
      todoGroups: todoGroups,
      tagGroups: tagGroups,
      busy: busy,
      onSubmit: (_) => Navigator.of(context).pop(),
      onCreateTag: (_) {},
    ),
  );
}
