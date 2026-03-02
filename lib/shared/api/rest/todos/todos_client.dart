// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/resource_scope.dart';
import '../models/timer_read.dart';
import '../models/todo_create.dart';
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
  @POST('/v1/todos')
  Future<TodoRead> createTodoV1TodosPost({
    @Body() required TodoCreate body,
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
  /// 그룹 필터링:.
  /// - group_ids: 해당 그룹에 속한 Todo 반환.
  ///   - tag_group_id로 직접 연결된 Todo.
  ///   - OR 해당 그룹의 태그를 가진 Todo.
  ///
  /// 태그 필터링:.
  /// - tag_ids: AND 방식 (모든 지정 태그를 포함한 Todo만 반환).
  /// - 태그 필터 시 조상 노드도 포함 (orphan 방지).
  ///
  /// 응답의 include_reason 필드:.
  /// - MATCH: 필터 조건에 직접 매칭된 Todo.
  /// - ANCESTOR: 매칭된 Todo의 조상이라 포함된 Todo.
  ///
  /// 둘 다 지정 시: 그룹 필터링 후 태그 필터링 적용.
  ///
  /// [scope] - 조회 범위: mine(내 Todo만), shared(공유된 Todo만), all(모두).
  ///
  /// [tagIds] - 태그 ID 리스트 (AND 방식: 모든 지정 태그를 포함한 Todo만 반환).
  ///
  /// [groupIds] - 태그 그룹 ID 리스트 (해당 그룹에 속한 Todo 반환 - 직접 연결 또는 태그 기반).
  @GET('/v1/todos')
  Future<List<TodoRead>> readTodosV1TodosGet({
    @Query('tag_ids') List<String>? tagIds,
    @Query('group_ids') List<String>? groupIds,
    @Query('scope') ResourceScope? scope = ResourceScope.mine,
    @DioOptions() RequestOptions? options,
  });

  /// Get Todo Stats.
  ///
  /// Todo 통계 조회.
  ///
  /// 그룹별 태그 통계를 반환합니다.
  /// group_id가 지정되면 해당 그룹의 태그만 집계합니다.
  ///
  /// [groupId] - 필터링할 태그 그룹 ID.
  @GET('/v1/todos/stats')
  Future<TodoStats> getTodoStatsV1TodosStatsGet({
    @Query('group_id') String? groupId,
    @DioOptions() RequestOptions? options,
  });

  /// Read Todo.
  ///
  /// ID로 Todo 조회 (공유된 Todo 포함).
  ///
  /// 본인 소유 Todo 또는 공유 접근 권한이 있는 Todo를 조회합니다.
  /// 접근 권한이 없으면 403 Forbidden을 반환합니다.
  @GET('/v1/todos/{todo_id}')
  Future<TodoRead> readTodoV1TodosTodoIdGet({
    @Path('todo_id') required String todoId,
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
  /// - deadline 변경: 기존 Schedule 업데이트.
  /// - deadline 제거: 기존 Schedule 삭제.
  @PATCH('/v1/todos/{todo_id}')
  Future<TodoRead> updateTodoV1TodosTodoIdPatch({
    @Path('todo_id') required String todoId,
    @Body() required TodoUpdate body,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Todo.
  ///
  /// Todo 삭제.
  @DELETE('/v1/todos/{todo_id}')
  Future<void> deleteTodoV1TodosTodoIdDelete({
    @Path('todo_id') required String todoId,
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
