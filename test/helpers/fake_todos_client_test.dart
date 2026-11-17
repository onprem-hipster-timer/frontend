import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/rest/export.dart';

import 'fake_rest_clients.dart';

/// [FakeTodosClient]가 서버처럼 할 일을 다른 그룹으로 옮기는지 본다.
void main() {
  TodoRead todo(String id, {String? parentId, String group = 'group-work'}) =>
      TodoRead(
        id: id,
        title: id,
        todoGroupId: group,
        parentId: parentId,
        status: TodoStatus.unscheduled,
        createdAt: DateTime.utc(2026, 1, 1),
      );

  late FakeTodosClient client;

  setUp(() {
    client = FakeTodosClient([
      todo('root'),
      todo('mid', parentId: 'root'),
      todo('leaf', parentId: 'mid'),
      todo('sibling', parentId: 'root'),
      todo('other'),
    ]);
  });

  Map<String, (String, String?)> state() => {
    for (final t in client.todos) t.id: (t.todoGroupId, t.parentId),
  };

  test('그룹을 바꾸면 그 할 일과 아래 할 일이 모두 옮겨지고 상위 연결이 풀린다', () async {
    final moved = await client.updateTodoV1TodosTodoIdPatch(
      todoId: 'mid',
      body: const TodoUpdate(todoGroupId: 'group-study'),
    );

    expect(moved.todoGroupId, 'group-study');
    expect(moved.parentId, isNull);
    expect(state(), {
      'root': ('group-work', null),
      'mid': ('group-study', null),
      'leaf': ('group-study', 'mid'),
      'sibling': ('group-work', 'root'),
      'other': ('group-work', null),
    });
  });

  test('최상위 할 일을 옮기면 하위 할 일이 상위 연결을 지닌 채 함께 옮겨진다', () async {
    await client.updateTodoV1TodosTodoIdPatch(
      todoId: 'root',
      body: const TodoUpdate(todoGroupId: 'group-study'),
    );

    expect(state(), {
      'root': ('group-study', null),
      'mid': ('group-study', 'root'),
      'leaf': ('group-study', 'mid'),
      'sibling': ('group-study', 'root'),
      'other': ('group-work', null),
    });
  });

  test('그룹이 같거나 없으면 아무것도 옮기지 않는다', () async {
    final before = state();
    await client.updateTodoV1TodosTodoIdPatch(
      todoId: 'mid',
      body: const TodoUpdate(todoGroupId: 'group-work'),
    );
    await client.updateTodoV1TodosTodoIdPatch(
      todoId: 'mid',
      body: const TodoUpdate(title: '이름만'),
    );

    expect(state(), before);
  });
}
