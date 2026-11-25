import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading, AsyncValue;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../shared/samples_shared.dart';
import 'samples_timer.dart';

enum _Load { done, loading, failed }

final _todos = [
  sampleTodo(),
  sampleTodo(title: '영어 단어 외우기').copyWith(id: 'todo-2'),
  sampleTodo(title: '운동 계획 세우기').copyWith(id: 'todo-3'),
];

@widgetbook.UseCase(name: '새 타이머 시트', type: StartTimerSheetView, path: '[타이머]')
Widget startTimerSheetView(BuildContext context) {
  final knobs = context.knobs;
  final linked = knobs.boolean(
    label: '할 일에서 시작',
    description: '할 일 줄의 타이머 버튼으로 열면 그 할 일과 제목을 채워 연다',
  );
  final exact = knobs.boolean(
    label: '초까지 고른 시간',
    description: '대시보드에서 초까지 고른 시간으로 열면 직접 입력 대신 그 시간과 변경을 둔다',
  );
  final load = knobs.object.dropdown(
    label: '할 일 목록',
    options: _Load.values,
    labelBuilder: (load) => switch (load) {
      _Load.done => '불러옴',
      _Load.loading => '불러오는 중',
      _Load.failed => '불러올 수 없음',
    },
    description: '불러오기 전에는 할 일 칸을 누를 수 없고, 못 불러오면 칸 아래에 알린다',
  );
  final AsyncValue<List<TodoRead>> todos = switch (load) {
    _Load.done => AsyncData(_todos),
    _Load.loading => const AsyncLoading(),
    _Load.failed => AsyncError(Exception('불러오기 실패'), StackTrace.empty),
  };
  // 앱에서는 타이머 대시보드의 시작 버튼이나 새 타이머 칩, 할 일 줄의 타이머 버튼을 누르면 아래에서 올라온다.
  // 할 일 칸을 누르면 할 일 둘을 고른 것으로 돌아와 제목 칸이 막힌다.
  // 노브를 바꾸면 입력한 값을 버리고 처음부터 채운다
  return SheetPreview(
    child: StartTimerSheetView(
      key: ValueKey((linked, exact)),
      initialDuration: exact
          ? const Duration(minutes: 12, seconds: 34)
          : const Duration(minutes: 25),
      initialTodo: linked ? _todos.first : null,
      todos: todos,
      onPickTodos: (_) async => _todos.take(2).toList(),
    ),
  );
}
