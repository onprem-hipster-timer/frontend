import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/todo/presentation/pages/todo_picker_page.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/features/timer/presentation/widgets/start_timer_sheet_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

export 'package:momeet/features/timer/presentation/widgets/start_timer_sheet_view.dart'
    show StartTimerInput;

/// 새 타이머에 연결할 수 있는 할 일인지. 서버는 내 할 일만 연결하고, 완료·취소한 할 일은 고르지 않는다
bool canLinkTimer(TodoRead todo) =>
    !todo.isShared &&
    todo.status != TodoStatus.done &&
    todo.status != TodoStatus.cancelled;

/// 타이머를 시작하지 못한 [failed] 할 일을 알리는 문구
String startFailureMessage(List<TodoRead> failed) =>
    '${Terms.timer} 시작 실패: ${failed.map((todo) => todo.title).join(', ')}';

/// 새 작업 시작 시트. 집중 시간을 [initialDuration]으로, 할 일을 [initialTodo]로 채워 연다. 닫으면 null. 칸은 [StartTimerSheetView]
///
/// [initialDuration]에 초가 있으면 직접 입력 칸 대신 그 시간을 그대로 보이고 '변경'으로 '시간 정하기'를 다시 연다.
/// 집중 시간 칩을 누르면 직접 입력으로 돌아간다.
/// 할 일은 [showTodoPicker]로 [canLinkTimer]인 것 중에서 고른다.
/// 할 일을 하나 고르면 작업 제목이 비었거나 앞서 고른 할 일의 제목 그대로일 때 그 제목으로 채운다.
/// 둘 이상 고르면 작업 제목 칸을 막고, 할 일마다 그 제목으로 타이머를 하나씩 시작한다.
///
/// 테스트: test/features/timer/presentation/widgets/start_timer_sheet_test.dart
Future<StartTimerInput?> showStartTimerSheet(
  BuildContext context, {
  required Duration initialDuration,
  TodoRead? initialTodo,
}) => showAppSheet<StartTimerInput>(
  context,
  builder: (_) => _StartTimerSheet(
    initialDuration: initialDuration,
    initialTodo: initialTodo,
  ),
);

class _StartTimerSheet extends ConsumerWidget {
  const _StartTimerSheet({required this.initialDuration, this.initialTodo});

  final Duration initialDuration;
  final TodoRead? initialTodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StartTimerSheetView(
      initialDuration: initialDuration,
      initialTodo: initialTodo,
      todos: ref.watch(allTodosProvider),
      onPickTodos: (selected) =>
          showTodoPicker(context, selectable: canLinkTimer, selected: selected),
    );
  }
}
