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

/// 메모리에 할 일을 들고 있는 [TodosClient]. 받은 요청을 기록한다.
class FakeTodosClient extends Fake implements TodosClient {
  FakeTodosClient([List<TodoRead> todos = const []]) : todos = [...todos];

  final List<TodoRead> todos;

  final created = <TodoCreate>[];
  final updated = <(String, TodoUpdate, RequestOptions?)>[];
  final deleted = <(String, LinkedSchedulePolicy?, LinkedTimerPolicy?)>[];

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
    List<String>? groupIds,
    String? timezone,
    ResourceScope? scope = ResourceScope.mine,
    RequestOptions? options,
  }) async {
    readGroupIds.add(groupIds);
    final failures = readFailures;
    if (readError != null && (failures == null || failures > 0)) {
      if (failures != null) readFailures = failures - 1;
      throw readError!;
    }
    return [
      for (final todo in todos)
        if (groupIds == null || groupIds.contains(todo.tagGroupId)) todo,
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
      tagGroupId: body.tagGroupId,
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
            tagGroupId: '',
            status: TodoStatus.unscheduled,
            createdAt: _at,
          );
    final next = old.copyWith(
      title: body.title ?? old.title,
      status: body.status ?? old.status,
      parentId: body.parentId ?? old.parentId,
    );
    if (index >= 0) todos[index] = next;
    return next;
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
  final convertedToTodo = <(String, String)>[];

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
    required String tagGroupId,
    RequestOptions? options,
  }) async {
    _failWrite();
    convertedToTodo.add((scheduleId, tagGroupId));
  }
}

/// 약관 동의 테스트용 현재 약관 버전.
const testConsentVersion = '2026-11-01';

/// 메모리에 내 프로필을 들고 있는 [UsersClient]. 받은 동의 요청을 기록한다.
///
/// 동의하면 [profile]의 `consentRequired`가 false가 된다.
class FakeUsersClient extends Fake implements UsersClient {
  FakeUsersClient({
    bool consentRequired = true,
    String consentVersion = testConsentVersion,
  }) : profile = MyProfileRead(
         id: 'test-uid',
         friendCode: 'FRIEND01',
         consentVersion: consentVersion,
         consentRequired: consentRequired,
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
    profile = profile.copyWith(consentRequired: false);
    return profile;
  }
}

/// 서버가 [statusCode]로 거절한 요청의 오류.
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
