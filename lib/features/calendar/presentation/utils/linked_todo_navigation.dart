import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/router.dart';

/// [scheduleId]와 이어진 할 일이 있는 할 일 그룹으로 간다. 할 일을 받지 못하면 할 일 탭으로 간다.
/// 화면이 사라진 뒤에도 부를 수 있게 [ProviderContainer]와 [GoRouter]를 받는다
///
/// 테스트: test/features/calendar/presentation/pages/schedule_detail_actions_test.dart
Future<void> goToTodoOfSchedule(
  ProviderContainer container,
  GoRouter router,
  String scheduleId,
) async {
  final provider = scheduleDetailProvider(scheduleId);
  // 받는 동안 autoDispose 프로바이더를 붙잡아 둔다
  final keepAlive = container.listen(provider, (_, _) {});
  String? groupId;
  try {
    final todoId = (await container.read(provider.future)).sourceTodoId;
    if (todoId != null) groupId = await todoGroupIdOf(container, todoId);
  } catch (_) {
    groupId = null;
  } finally {
    keepAlive.close();
  }
  goToTodoGroup(router, groupId);
}

/// [todoId] 할 일이 든 할 일 그룹 id. 받지 못하면 null
Future<String?> todoGroupIdOf(
  ProviderContainer container,
  String todoId,
) async {
  final provider = todoByIdProvider(todoId);
  // 받는 동안 autoDispose 프로바이더를 붙잡아 둔다
  final keepAlive = container.listen(provider, (_, _) {});
  try {
    return (await container.read(provider.future)).todoGroupId;
  } catch (_) {
    return null;
  } finally {
    keepAlive.close();
  }
}

/// [groupId] 할 일 그룹 화면으로 간다. null이면 할 일 탭으로 간다
void goToTodoGroup(GoRouter router, String? groupId) {
  if (groupId == null) {
    router.goNamed(AppRoute.todo.name);
  } else {
    router.goNamed(
      AppRoute.todoGroupDetail.name,
      pathParameters: {'groupId': groupId},
    );
  }
}
