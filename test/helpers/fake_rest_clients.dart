import 'package:dio/dio.dart'
    show DioException, DioExceptionType, RequestOptions, Response;
import 'package:mocktail/mocktail.dart';
import 'package:momeet/shared/api/rest/export.dart';

final _at = DateTime.utc(2026, 1, 1);

/// 테스트용 태그 그룹(하위 태그 포함).
TagGroupReadWithTags makeTagGroup({
  String id = 'group-1',
  String name = '업무',
  String color = '#2196F3',
  String? description,
  List<TagRead> tags = const [],
}) => TagGroupReadWithTags(
  id: id,
  name: name,
  color: color,
  description: description,
  createdAt: _at,
  updatedAt: _at,
  tags: tags,
);

/// 메모리에 태그 그룹을 들고 있는 [TagsClient]. 받은 요청을 기록한다.
class FakeTagsClient extends Fake implements TagsClient {
  FakeTagsClient([List<TagGroupReadWithTags> groups = const []])
    : groups = [...groups];

  final List<TagGroupReadWithTags> groups;

  final createdGroups = <TagGroupCreate>[];
  final updatedGroups = <(String, TagGroupUpdate, RequestOptions?)>[];
  final deletedGroups = <String>[];
  final createdTags = <TagCreate>[];
  final updatedTags = <(String, TagUpdate, RequestOptions?)>[];
  final deletedTags = <String>[];

  /// 설정하면 목록 조회가 이 오류로 실패한다.
  Object? readError;

  /// 설정하면 쓰기 요청이 이 오류로 실패한다.
  Object? writeError;

  void _failWrite() {
    if (writeError != null) throw writeError!;
  }

  @override
  Future<List<TagGroupReadWithTags>> readTagGroupsV1TagsGroupsGet({
    RequestOptions? options,
  }) async {
    if (readError != null) throw readError!;
    return [...groups];
  }

  @override
  Future<TagGroupRead> createTagGroupV1TagsGroupsPost({
    required TagGroupCreate body,
    RequestOptions? options,
  }) async {
    _failWrite();
    createdGroups.add(body);
    final group = makeTagGroup(
      id: 'group-new-${createdGroups.length}',
      name: body.name,
      color: body.color,
      description: body.description,
    );
    groups.add(group);
    return TagGroupRead(
      id: group.id,
      name: group.name,
      color: group.color,
      description: group.description,
      createdAt: _at,
      updatedAt: _at,
    );
  }

  @override
  Future<TagGroupRead> updateTagGroupV1TagsGroupsGroupIdPatch({
    required String groupId,
    required TagGroupUpdate body,
    RequestOptions? options,
  }) async {
    _failWrite();
    updatedGroups.add((groupId, body, options));
    final index = groups.indexWhere((g) => g.id == groupId);
    final old = groups[index];
    final next = old.copyWith(
      name: body.name ?? old.name,
      color: body.color ?? old.color,
      description: body.description ?? old.description,
    );
    groups[index] = next;
    return TagGroupRead(
      id: next.id,
      name: next.name,
      color: next.color,
      description: next.description,
      createdAt: _at,
      updatedAt: _at,
    );
  }

  @override
  Future<void> deleteTagGroupV1TagsGroupsGroupIdDelete({
    required String groupId,
    RequestOptions? options,
  }) async {
    _failWrite();
    deletedGroups.add(groupId);
    groups.removeWhere((g) => g.id == groupId);
  }

  @override
  Future<TagRead> createTagV1TagsPost({
    required TagCreate body,
    RequestOptions? options,
  }) async {
    _failWrite();
    createdTags.add(body);
    final tag = TagRead(
      id: 'tag-new-${createdTags.length}',
      name: body.name,
      color: body.color,
      groupId: body.groupId,
      description: body.description,
      createdAt: _at,
      updatedAt: _at,
    );
    final index = groups.indexWhere((g) => g.id == body.groupId);
    if (index >= 0) {
      groups[index] = groups[index].copyWith(
        tags: [...groups[index].tags, tag],
      );
    }
    return tag;
  }

  @override
  Future<TagRead> updateTagV1TagsTagIdPatch({
    required String tagId,
    required TagUpdate body,
    RequestOptions? options,
  }) async {
    _failWrite();
    updatedTags.add((tagId, body, options));
    for (final group in groups) {
      for (final tag in group.tags) {
        if (tag.id == tagId) return tag;
      }
    }
    throw StateError('no tag $tagId');
  }

  @override
  Future<void> deleteTagV1TagsTagIdDelete({
    required String tagId,
    RequestOptions? options,
  }) async {
    _failWrite();
    deletedTags.add(tagId);
    for (var i = 0; i < groups.length; i++) {
      groups[i] = groups[i].copyWith(
        tags: groups[i].tags.where((t) => t.id != tagId).toList(),
      );
    }
  }
}

/// 테스트용 할 일 그룹.
TodoGroupRead makeTodoGroup({
  String id = 'group-1',
  String name = '업무',
  String color = '#2196F3',
  String? description,
  bool isDefault = false,
}) => TodoGroupRead(
  id: id,
  name: name,
  color: color,
  description: description,
  isDefault: isDefault,
  createdAt: _at,
  updatedAt: _at,
);

/// 할 일 그룹 없이 만든 할 일이 들어가는 가짜 기본 그룹 id
const defaultTodoGroupId = 'group-default';

/// [FakeTodosClient]가 늘 갖는 기본 할 일 그룹
final defaultTodoGroup = makeTodoGroup(
  id: defaultTodoGroupId,
  name: '기본',
  isDefault: true,
);

/// 메모리에 할 일과 할 일 그룹을 들고 있는 [TodosClient]. 받은 요청을 기록한다.
///
/// 할 일 그룹은 서버처럼 기본 그룹이 늘 있고([groups]에 없으면 [defaultTodoGroup]을 넣는다),
/// 기본 먼저·이름순으로 준다. 그룹을 지우면 그 그룹의 할 일은 기본 그룹으로 옮겨진다.
/// 할 일의 그룹을 바꾸면 하위 할 일도 함께 옮겨지고, 상위 할 일이 옛 그룹에 남으면 상위 연결이 풀린다.
class FakeTodosClient extends Fake implements TodosClient {
  FakeTodosClient([
    List<TodoRead> todos = const [],
    List<TodoGroupRead> groups = const [],
  ]) : todos = [...todos],
       groups = [
         if (!groups.any((g) => g.isDefault)) defaultTodoGroup,
         ...groups,
       ];

  final List<TodoRead> todos;
  final List<TodoGroupRead> groups;

  final created = <TodoCreate>[];
  final updated = <(String, TodoUpdate, RequestOptions?)>[];
  final deleted = <(String, LinkedSchedulePolicy?, LinkedTimerPolicy?)>[];
  final createdGroups = <TodoGroupCreate>[];
  final updatedGroups = <(String, TodoGroupUpdate, RequestOptions?)>[];
  final deletedGroups = <String>[];

  /// 설정하면 할 일 그룹 목록 조회가 이 오류로 실패한다.
  Object? groupsReadError;

  /// 목록 조회마다 받은 `group_ids` 필터.
  final readGroupIds = <List<String>?>[];

  /// 설정하면 목록 조회가 이 오류로 실패한다.
  Object? readError;

  /// 주면 [readError]로 이만큼만 실패하고 그 뒤로는 성공한다. 없으면 계속 실패한다.
  int? readFailures;

  /// 설정하면 쓰기 요청이 이 오류로 실패한다.
  Object? writeError;

  void _failWrite() {
    if (writeError != null) throw writeError!;
  }

  @override
  Future<List<TodoRead>> readTodosV1TodosGet({
    List<String>? tagIds,
    List<String>? todoGroupIds,
    String? timezone,
    ResourceScope? scope = ResourceScope.mine,
    RequestOptions? options,
  }) async {
    readGroupIds.add(todoGroupIds);
    final failures = readFailures;
    if (readError != null && (failures == null || failures > 0)) {
      if (failures != null) readFailures = failures - 1;
      throw readError!;
    }
    return [
      for (final todo in todos)
        if (todoGroupIds == null || todoGroupIds.contains(todo.todoGroupId))
          todo,
    ];
  }

  @override
  Future<TodoRead> createTodoV1TodosPost({
    required TodoCreate body,
    String? timezone,
    RequestOptions? options,
  }) async {
    _failWrite();
    created.add(body);
    final todo = TodoRead(
      id: 'todo-new-${created.length}',
      title: body.title,
      todoGroupId: body.todoGroupId ?? defaultTodoGroupId,
      parentId: body.parentId,
      description: body.description,
      deadline: body.deadline,
      status: body.status ?? TodoStatus.unscheduled,
      createdAt: _at,
    );
    todos.add(todo);
    return todo;
  }

  @override
  Future<TodoRead> updateTodoV1TodosTodoIdPatch({
    required String todoId,
    required TodoUpdate body,
    String? timezone,
    RequestOptions? options,
  }) async {
    _failWrite();
    updated.add((todoId, body, options));
    final index = todos.indexWhere((t) => t.id == todoId);
    final old = index >= 0
        ? todos[index]
        : TodoRead(
            id: todoId,
            title: '',
            todoGroupId: '',
            status: TodoStatus.unscheduled,
            createdAt: _at,
          );
    var next = old.copyWith(
      title: body.title ?? old.title,
      status: body.status ?? old.status,
      parentId: body.parentId ?? old.parentId,
    );
    final groupId = body.todoGroupId;
    if (index >= 0 && groupId != null && groupId != old.todoGroupId) {
      final moved = _subtreeIds(todoId);
      for (var i = 0; i < todos.length; i++) {
        if (moved.contains(todos[i].id)) {
          todos[i] = todos[i].copyWith(todoGroupId: groupId);
        }
      }
      final parent = todos.where((t) => t.id == next.parentId).firstOrNull;
      next = next.copyWith(
        todoGroupId: groupId,
        parentId: parent?.todoGroupId == groupId ? next.parentId : null,
      );
    }
    if (index >= 0) todos[index] = next;
    return next;
  }

  /// [rootId]와 그 아래 모든 할 일의 id
  Set<String> _subtreeIds(String rootId) {
    final ids = {rootId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final todo in todos) {
        if (todo.parentId != null &&
            ids.contains(todo.parentId) &&
            ids.add(todo.id)) {
          grew = true;
        }
      }
    }
    return ids;
  }

  @override
  Future<void> deleteTodoV1TodosTodoIdDelete({
    required String todoId,
    LinkedSchedulePolicy? linkedSchedulePolicy,
    LinkedTimerPolicy? linkedTimerPolicy,
    RequestOptions? options,
  }) async {
    _failWrite();
    deleted.add((todoId, linkedSchedulePolicy, linkedTimerPolicy));
    todos.removeWhere((t) => t.id == todoId);
  }

  @override
  Future<List<TodoGroupRead>> readTodoGroupsV1TodosGroupsGet({
    RequestOptions? options,
  }) async {
    if (groupsReadError != null) throw groupsReadError!;
    return [
      ...groups.where((g) => g.isDefault),
      ...groups.where((g) => !g.isDefault).toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
    ];
  }

  @override
  Future<TodoGroupRead> createTodoGroupV1TodosGroupsPost({
    required TodoGroupCreate body,
    RequestOptions? options,
  }) async {
    _failWrite();
    createdGroups.add(body);
    final group = makeTodoGroup(
      id: 'todo-group-new-${createdGroups.length}',
      name: body.name,
      color: body.color,
      description: body.description,
    );
    groups.add(group);
    return group;
  }

  @override
  Future<TodoGroupRead> updateTodoGroupV1TodosGroupsGroupIdPatch({
    required String groupId,
    required TodoGroupUpdate body,
    RequestOptions? options,
  }) async {
    _failWrite();
    updatedGroups.add((groupId, body, options));
    final index = groups.indexWhere((g) => g.id == groupId);
    final old = groups[index];
    final next = old.copyWith(
      name: body.name ?? old.name,
      color: body.color ?? old.color,
      description: explicitNullFields(options).contains('description')
          ? null
          : body.description ?? old.description,
    );
    groups[index] = next;
    return next;
  }

  @override
  Future<void> deleteTodoGroupV1TodosGroupsGroupIdDelete({
    required String groupId,
    RequestOptions? options,
  }) async {
    _failWrite();
    deletedGroups.add(groupId);
    groups.removeWhere((g) => g.id == groupId);
    final defaultId = groups.firstWhere((g) => g.isDefault).id;
    for (var i = 0; i < todos.length; i++) {
      if (todos[i].todoGroupId == groupId) {
        todos[i] = todos[i].copyWith(todoGroupId: defaultId);
      }
    }
  }
}

/// [explicitNulls]로 null을 보내라고 표시한 필드들.
List<String> explicitNullFields(RequestOptions? options) =>
    (options?.extra['explicit_nulls'] as List<String>?) ?? const [];

/// 메모리에 일정을 들고 있는 [SchedulesClient]. 받은 요청을 기록한다.
class FakeSchedulesClient extends Fake implements SchedulesClient {
  FakeSchedulesClient([List<ScheduleRead> schedules = const []])
    : schedules = [...schedules];

  final List<ScheduleRead> schedules;

  final created = <ScheduleCreate>[];
  final updated = <(String, ScheduleUpdate, RequestOptions?)>[];
  final deleted = <(String, SourceTodoPolicy?, LinkedTimerPolicy?)>[];
  final convertedToTodo = <(String, String?)>[];

  /// 설정하면 조회가 이 오류로 실패한다.
  Object? readError;

  /// 설정하면 쓰기 요청이 이 오류로 실패한다.
  Object? writeError;

  void _failWrite() {
    if (writeError != null) throw writeError!;
  }

  @override
  Future<List<ScheduleRead>> readSchedulesV1SchedulesGet({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? tagIds,
    List<String>? groupIds,
    String? timezone,
    ResourceScope? scope = ResourceScope.mine,
    RequestOptions? options,
  }) async {
    if (readError != null) throw readError!;
    return [...schedules];
  }

  @override
  Future<ScheduleRead> readScheduleV1SchedulesScheduleIdGet({
    required String scheduleId,
    String? timezone,
    RequestOptions? options,
  }) async {
    if (readError != null) throw readError!;
    return schedules.firstWhere((s) => s.id == scheduleId);
  }

  @override
  Future<ScheduleRead> createScheduleV1SchedulesPost({
    required ScheduleCreate body,
    String? timezone,
    RequestOptions? options,
  }) async {
    _failWrite();
    created.add(body);
    final schedule = ScheduleRead(
      id: 'schedule-new-${created.length}',
      title: body.title,
      startTime: body.startTime,
      endTime: body.endTime,
      description: body.description,
      state: ScheduleState.planned,
      createdAt: _at,
    );
    schedules.add(schedule);
    return schedule;
  }

  @override
  Future<ScheduleRead> updateScheduleV1SchedulesScheduleIdPatch({
    required String scheduleId,
    required ScheduleUpdate body,
    DateTime? instanceStart,
    String? timezone,
    RequestOptions? options,
  }) async {
    _failWrite();
    updated.add((scheduleId, body, options));
    final index = schedules.indexWhere((s) => s.id == scheduleId);
    final old = schedules[index];
    final next = old.copyWith(
      title: body.title ?? old.title,
      startTime: body.startTime ?? old.startTime,
      endTime: body.endTime ?? old.endTime,
    );
    schedules[index] = next;
    return next;
  }

  @override
  Future<void> deleteScheduleV1SchedulesScheduleIdDelete({
    required String scheduleId,
    DateTime? instanceStart,
    SourceTodoPolicy? sourceTodoPolicy,
    LinkedTimerPolicy? linkedTimerPolicy,
    RequestOptions? options,
  }) async {
    _failWrite();
    deleted.add((scheduleId, sourceTodoPolicy, linkedTimerPolicy));
    schedules.removeWhere((s) => s.id == scheduleId);
  }

  @override
  Future<void> createTodoFromScheduleV1SchedulesScheduleIdTodoPost({
    required String scheduleId,
    String? todoGroupId,
    RequestOptions? options,
  }) async {
    _failWrite();
    convertedToTodo.add((scheduleId, todoGroupId));
  }
}

/// 약관 동의 테스트용 현재 약관 버전.
const testConsentVersion = '2026-11-01';

/// 탈퇴 테스트에서 신청한 시각. 파기는 3일 뒤다.
final testDeletionRequestedAt = DateTime.utc(2026, 11, 11, 3);

/// 메모리에 내 프로필을 들고 있는 [UsersClient]. 받은 동의·탈퇴 요청을 기록한다.
///
/// 동의하면 [profile]의 `consentRequired`가 false가 된다. 탈퇴를 신청하면
/// [testDeletionRequestedAt]에 신청한 것이 되고(이미 신청했으면 그대로), 취소하면 지워진다.
/// 탈퇴 대기 중에는 동의 요청을 423으로 거절한다.
class FakeUsersClient extends Fake implements UsersClient {
  FakeUsersClient({
    bool consentRequired = true,
    String consentVersion = testConsentVersion,
    bool deletionPending = false,
  }) : profile = MyProfileRead(
         id: 'test-uid',
         friendCode: 'FRIEND01',
         consentVersion: consentVersion,
         consentRequired: consentRequired,
         deletionRequestedAt: deletionPending ? testDeletionRequestedAt : null,
         deletionScheduledAt: deletionPending
             ? testDeletionRequestedAt.add(const Duration(days: 3))
             : null,
       );

  MyProfileRead profile;

  /// 프로필 조회 횟수
  int reads = 0;

  final agreed = <ConsentCreate>[];

  /// 설정하면 프로필 조회가 이 오류로 실패한다.
  Object? readError;

  /// 설정하면 프로필 조회가 이것이 끝날 때까지 기다린다.
  Future<void>? readGate;

  /// 설정하면 동의 요청이 이 오류로 실패한다.
  Object? consentError;

  /// 설정하면 동의 요청이 이것이 끝날 때까지 기다린다.
  Future<void>? consentGate;

  /// 탈퇴 신청(POST) 횟수
  int deletionRequests = 0;

  /// 탈퇴 취소(DELETE) 횟수
  int deletionCancels = 0;

  /// 설정하면 탈퇴 신청·취소가 이 오류로 실패한다.
  Object? deletionError;

  /// 설정하면 탈퇴 신청·취소가 이것이 끝날 때까지 기다린다.
  Future<void>? deletionGate;

  @override
  Future<MyProfileRead> getMyProfileV1UsersMeGet({
    RequestOptions? options,
  }) async {
    reads++;
    await readGate;
    if (readError != null) throw readError!;
    return profile;
  }

  @override
  Future<MyProfileRead> putMyConsentV1UsersMeConsentPut({
    required ConsentCreate body,
    RequestOptions? options,
  }) async {
    agreed.add(body);
    await consentGate;
    if (consentError != null) throw consentError!;
    if (profile.deletionRequestedAt != null) {
      throw httpError(
        '/v1/users/me/consent',
        423,
        data: {'message': 'account_deletion_pending'},
      );
    }
    profile = profile.copyWith(consentRequired: false);
    return profile;
  }

  @override
  Future<MyProfileRead> requestMyDeletionV1UsersMeDeletionPost({
    RequestOptions? options,
  }) async {
    deletionRequests++;
    await deletionGate;
    if (deletionError != null) throw deletionError!;
    final requestedAt = profile.deletionRequestedAt ?? testDeletionRequestedAt;
    profile = profile.copyWith(
      deletionRequestedAt: requestedAt,
      deletionScheduledAt: requestedAt.add(const Duration(days: 3)),
    );
    return profile;
  }

  @override
  Future<MyProfileRead> cancelMyDeletionV1UsersMeDeletionDelete({
    RequestOptions? options,
  }) async {
    deletionCancels++;
    await deletionGate;
    if (deletionError != null) throw deletionError!;
    profile = profile.copyWith(
      deletionRequestedAt: null,
      deletionScheduledAt: null,
    );
    return profile;
  }
}

/// 서버가 [statusCode]로 거절한 요청의 오류. [data]는 응답 본문이다.
DioException httpError(String path, int statusCode, {Object? data}) {
  final request = RequestOptions(path: path);
  return DioException(
    requestOptions: request,
    response: Response(
      requestOptions: request,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}
