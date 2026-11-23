import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 할 일 상태를 고르면 서버에 보내는 대신 그 상태의 할 일을 바로 돌려준다. 고른 화면은 돌려받은 상태만 쓴다
class SampleTodoMutations extends TodoMutationsNotifier {
  @override
  Future<TodoRead> changeStatus(String todoId, TodoStatus newStatus) async =>
      TodoRead(
        id: todoId,
        title: '',
        todoGroupId: '',
        status: newStatus,
        createdAt: DateTime.utc(2026, 3, 2),
      );
}
