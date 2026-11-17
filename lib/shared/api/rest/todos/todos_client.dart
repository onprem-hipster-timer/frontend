// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/linked_schedule_policy.dart';
import '../models/linked_timer_policy.dart';
import '../models/resource_scope.dart';
import '../models/timer_read.dart';
import '../models/todo_create.dart';
import '../models/todo_group_create.dart';
import '../models/todo_group_read.dart';
import '../models/todo_group_update.dart';
import '../models/todo_read.dart';
import '../models/todo_stats.dart';
import '../models/todo_update.dart';

part 'todos_client.g.dart';

@RestApi()
abstract class TodosClient {
  factory TodosClient(Dio dio, {String? baseUrl}) = _TodosClient;

  /// Create Todo.
  ///
  /// 새 Todo 생성.
  ///
  /// Todo는 독립적인 엔티티입니다.
  /// deadline이 있으면 별도의 Schedule이 자동으로 생성됩니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/todos')
  Future<TodoRead> createTodoV1TodosPost({
    @Body() required TodoCreate body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Read Todos.
  ///
  /// Todo 목록 조회 (태그/그룹 필터링 지원).
  ///
  /// 조회 범위 (scope):.
  /// - mine: 내 Todo만 (기본값).
  /// - shared: 공유된 타인의 Todo만.
  /// - all: 내 Todo + 공유된 Todo.
  ///
  /// 할 일 그룹 필터링:.
  /// - todo_group_ids: 해당 할 일 그룹에 속한 Todo 반환.
  ///
  /// 태그 필터링:.
  /// - tag_ids: AND 방식 (모든 지정 태그를 포함한 Todo만 반환).
  /// - 태그 필터 시 조상 노드도 포함 (orphan 방지).
  ///
  /// 응답의 include_reason 필드:.
  /// - MATCH: 필터 조건에 직접 매칭된 Todo.
  /// - ANCESTOR: 매칭된 Todo의 조상이라 포함된 Todo.
  ///
  /// 둘 다 지정 시: 할 일 그룹 필터링 후 태그 필터링 적용.
  ///
  /// [scope] - 조회 범위: mine(내 Todo만), shared(공유된 Todo만), all(모두).
  ///
  /// [tagIds] - 태그 ID 리스트 (AND 방식: 모든 지정 태그를 포함한 Todo만 반환).
  ///
  /// [todoGroupIds] - 할 일 그룹 ID 리스트 (해당 할 일 그룹에 속한 Todo만 반환).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/todos')
  Future<List<TodoRead>> readTodosV1TodosGet({
    @Query('tag_ids') List<String>? tagIds,
    @Query('todo_group_ids') List<String>? todoGroupIds,
    @Query('timezone') String? timezone,
    @Query('scope') ResourceScope? scope = ResourceScope.mine,
    @DioOptions() RequestOptions? options,
  });

  /// Read Todo Groups.
  ///
  /// 모든 할 일 그룹 조회 (기본 그룹 먼저, 나머지는 이름순).
  ///
  /// 기본 그룹이 없으면 만든다. 받은 기본 그룹 id로 곧바로 할 일을 만들 수 있게 응답 전에 커밋한다.
  @GET('/v1/todos/groups')
  Future<List<TodoGroupRead>> readTodoGroupsV1TodosGroupsGet({
    @DioOptions() RequestOptions? options,
  });

  /// Create Todo Group.
  ///
  /// 할 일 그룹 생성.
  @POST('/v1/todos/groups')
  Future<TodoGroupRead> createTodoGroupV1TodosGroupsPost({
    @Body() required TodoGroupCreate body,
    @DioOptions() RequestOptions? options,
  });

  /// Read Todo Group.
  ///
  /// 할 일 그룹 조회.
  @GET('/v1/todos/groups/{group_id}')
  Future<TodoGroupRead> readTodoGroupV1TodosGroupsGroupIdGet({
    @Path('group_id') required String groupId,
    @DioOptions() RequestOptions? options,
  });

  /// Update Todo Group.
  ///
  /// 할 일 그룹의 이름·색·설명 수정 (기본 그룹 포함).
  @PATCH('/v1/todos/groups/{group_id}')
  Future<TodoGroupRead> updateTodoGroupV1TodosGroupsGroupIdPatch({
    @Path('group_id') required String groupId,
    @Body() required TodoGroupUpdate body,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Todo Group.
  ///
  /// 할 일 그룹 삭제. 기본 그룹은 409.
  @DELETE('/v1/todos/groups/{group_id}')
  Future<void> deleteTodoGroupV1TodosGroupsGroupIdDelete({
    @Path('group_id') required String groupId,
    @DioOptions() RequestOptions? options,
  });

  /// Get Todo Stats.
  ///
  /// Todo 통계 조회.
  ///
  /// 태그별 할 일 수를 반환합니다.
  /// todo_group_id가 지정되면 그 할 일 그룹의 할 일만 셉니다.
  ///
  /// [todoGroupId] - 필터링할 할 일 그룹 ID.
  @GET('/v1/todos/stats')
  Future<TodoStats> getTodoStatsV1TodosStatsGet({
    @Query('todo_group_id') String? todoGroupId,
    @DioOptions() RequestOptions? options,
  });

  /// Read Todo.
  ///
  /// ID로 Todo 조회 (공유된 Todo 포함).
  ///
  /// 본인 소유 Todo 또는 공유 접근 권한이 있는 Todo를 조회합니다.
  /// 접근 권한이 없으면 403 Forbidden을 반환합니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/todos/{todo_id}')
  Future<TodoRead> readTodoV1TodosTodoIdGet({
    @Path('todo_id') required String todoId,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Update Todo.
  ///
  /// Todo 업데이트.
  ///
  /// title, description, tag_ids, deadline, parent_id, status를 업데이트할 수 있습니다.
  ///
  /// deadline 변경 시:.
  /// - deadline 추가: 새 Schedule 생성.
  /// - deadline 변경: 기존 Schedule 시작 시간 이동 (길이 보존, 없으면 재생성).
  /// - deadline 제거(null): 연결 Schedule이 있으면 linked_schedule_policy 필수.
  ///   (delete: 삭제 / unlink: 연결만 해제).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @PATCH('/v1/todos/{todo_id}')
  Future<TodoRead> updateTodoV1TodosTodoIdPatch({
    @Path('todo_id') required String todoId,
    @Body() required TodoUpdate body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Todo.
  ///
  /// Todo 삭제.
  ///
  /// 연결된 투영 Schedule은 `linked_schedule_policy`, 연결된 타이머는.
  /// `linked_timer_policy`에 따라 처리됩니다. 연결 대상이 있는데 해당 정책이.
  /// 누락되면 422를 반환합니다.
  ///
  /// [linkedSchedulePolicy] - 연결 투영 Schedule 처리 정책 — 연결 투영이 있는 경우 필수, 서버 기본값 없음. delete: 투영 삭제 + 접근권한 정리 / unlink: 연결만 해제(일정 보존).
  ///
  /// [linkedTimerPolicy] - 연결 타이머 처리 정책 — 연결 타이머가 있는 경우 필수, 서버 기본값 없음. delete: 타이머 삭제 + 접근권한 정리 / unlink: 연결만 해제(타이머 보존, 실행 중이면 계속 실행).
  @DELETE('/v1/todos/{todo_id}')
  Future<void> deleteTodoV1TodosTodoIdDelete({
    @Path('todo_id') required String todoId,
    @Query('linked_schedule_policy') LinkedSchedulePolicy? linkedSchedulePolicy,
    @Query('linked_timer_policy') LinkedTimerPolicy? linkedTimerPolicy,
    @DioOptions() RequestOptions? options,
  });

  /// Get Todo Timers.
  ///
  /// Todo의 모든 타이머 조회 (공유된 Todo 포함).
  ///
  /// Schedule의 /schedules/{schedule_id}/timers 엔드포인트와 동일한 패턴입니다.
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/todos/{todo_id}/timers')
  Future<List<TimerRead>> getTodoTimersV1TodosTodoIdTimersGet({
    @Path('todo_id') required String todoId,
    @Query('timezone') String? timezone,
    @Query('include_todo') bool? includeTodo = false,
    @DioOptions() RequestOptions? options,
  });

  /// Get Todo Active Timer.
  ///
  /// Todo의 현재 활성 타이머 조회 (RUNNING 또는 PAUSED, 공유된 Todo 포함).
  ///
  /// 활성 타이머가 없으면 404를 반환합니다.
  /// Schedule의 /schedules/{schedule_id}/timers/active 엔드포인트와 동일한 패턴입니다.
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/todos/{todo_id}/timers/active')
  Future<TimerRead> getTodoActiveTimerV1TodosTodoIdTimersActiveGet({
    @Path('todo_id') required String todoId,
    @Query('timezone') String? timezone,
    @Query('include_todo') bool? includeTodo = false,
    @DioOptions() RequestOptions? options,
  });
}
