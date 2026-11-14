import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/todo/presentation/utils/todo_form_submit.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/fake_rest_clients.dart';

void main() {
  final todo = TodoRead(
    id: 'todo-1',
    title: '보고서',
    todoGroupId: 'group-study',
    status: TodoStatus.unscheduled,
    createdAt: DateTime.utc(2026, 1, 1),
  );
  final groups = [
    makeTodoGroup(id: 'group-study', name: '학습'),
    makeTodoGroup(id: 'group-work', name: '업무'),
  ];

  TodoFormValues values(String? groupId) => (
    title: '보고서',
    description: '',
    status: TodoStatus.unscheduled,
    tagIds: const <String>[],
    deadline: null,
    todoGroupId: groupId,
  );

  test('다른 할 일 그룹으로 옮기면 그 그룹 이름을 알린다', () {
    expect(
      todoUpdatedMessage(todo, values('group-work'), groups),
      "'업무' 해야 할 일 목록으로 옮겼습니다",
    );
  });

  test('그룹이 그대로면 수정되었다고 알린다', () {
    expect(
      todoUpdatedMessage(todo, values('group-study'), groups),
      '할 일이 수정되었습니다',
    );
  });

  test('옮긴 그룹의 이름을 모르면 수정되었다고 알린다', () {
    expect(
      todoUpdatedMessage(todo, values('group-gone'), groups),
      '할 일이 수정되었습니다',
    );
    expect(
      todoUpdatedMessage(todo, values('group-work'), null),
      '할 일이 수정되었습니다',
    );
  });
}
