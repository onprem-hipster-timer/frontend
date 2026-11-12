import 'package:dio/dio.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/features/todo/presentation/providers/todo_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';

part 'todo_group_providers.g.dart';

/// 할 일 그룹 목록과 생성·수정·삭제.
///
/// 서버는 기본 그룹을 먼저, 나머지를 이름순으로 주고, 기본 그룹이 없으면 목록을 줄 때 만든다.
/// 생성·수정·삭제는 `mutation.run(ref, (tsx) => tsx.get(todoGroupsProvider.notifier).xxx())`로 부른다
/// (tag_providers.dart의 TagGroupsRaw와 같은 방식).
@riverpod
class TodoGroups extends _$TodoGroups {
  @override
  Future<List<TodoGroupRead>> build() =>
      ref.watch(todosApiProvider).readTodoGroupsV1TodosGroupsGet();

  /// 할 일 그룹 생성
  Future<void> createGroup(TodoGroupCreate data) async {
    await ref
        .read(todosApiProvider)
        .createTodoGroupV1TodosGroupsPost(body: data);
    ref.invalidateSelf();
  }

  /// 할 일 그룹 수정 (기본 그룹도 이름·색·설명을 바꿀 수 있다)
  Future<void> updateGroup(
    String groupId,
    TodoGroupUpdate data, {
    RequestOptions? options,
  }) async {
    await ref
        .read(todosApiProvider)
        .updateTodoGroupV1TodosGroupsGroupIdPatch(
          groupId: groupId,
          body: data,
          options: options,
        );
    ref.invalidateSelf();
  }

  /// 할 일 그룹 삭제. 서버가 그룹의 할 일을 기본 그룹으로 옮기므로 할 일 목록도 다시 받는다
  Future<void> deleteGroup(String groupId) async {
    await ref
        .read(todosApiProvider)
        .deleteTodoGroupV1TodosGroupsGroupIdDelete(groupId: groupId);
    ref.invalidateSelf();
    ref.invalidate(todosProvider);
  }
}

/// 기본 할 일 그룹. 목록을 받기 전이면 null
TodoGroupRead? defaultTodoGroupOf(List<TodoGroupRead>? groups) =>
    groups?.where((group) => group.isDefault).firstOrNull;

final createTodoGroupMutation = Mutation<void>(label: 'createTodoGroup');
final updateTodoGroupMutation = Mutation<void>(label: 'updateTodoGroup');
final deleteTodoGroupMutation = Mutation<void>(label: 'deleteTodoGroup');
