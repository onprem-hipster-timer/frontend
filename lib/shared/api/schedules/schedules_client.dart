// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/resource_scope.dart';
import '../models/schedule_create.dart';
import '../models/schedule_read.dart';
import '../models/schedule_update.dart';
import '../models/timer_read.dart';

part 'schedules_client.g.dart';

@RestApi()
abstract class SchedulesClient {
  factory SchedulesClient(Dio dio, {String? baseUrl}) = _SchedulesClient;

  /// Create Schedule.
  ///
  /// 새 일정 생성.
  ///
  /// FastAPI Best Practices:.
  /// - async 라우트 사용.
  /// - 트랜잭션 자동 관리 (context manager).
  /// - Exception Handler가 예외 처리.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/schedules')
  Future<ScheduleRead> createScheduleV1SchedulesPost({
    @Body() required ScheduleCreate body,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Read Schedules.
  ///
  /// 날짜 범위 기반 일정 조회 (반복 일정 포함, 태그 필터링 지원).
  ///
  /// 조회 범위 (scope):.
  /// - mine: 내 일정만 (기본값).
  /// - shared: 공유된 타인의 일정만.
  /// - all: 내 일정 + 공유된 일정.
  ///
  /// 날짜 범위:.
  /// - start_date: 조회 시작 날짜/시간 (필수).
  /// - end_date: 조회 종료 날짜/시간 (필수).
  /// - 지정된 날짜 범위와 겹치는 모든 일정을 반환 (반복 일정은 가상 인스턴스로 확장).
  ///
  /// 태그 필터링:.
  /// - tag_ids: AND 방식 (모든 지정 태그를 포함한 일정만 반환).
  /// - group_ids: 해당 그룹의 태그 중 하나라도 있는 일정 반환.
  /// - 둘 다 지정 시: 그룹 필터링 후 태그 필터링 적용.
  ///
  /// FastAPI Best Practices:.
  /// - async 라우트 사용.
  ///
  /// [startDate] - 조회 시작 날짜/시간 (ISO 8601 형식).
  ///
  /// [endDate] - 조회 종료 날짜/시간 (ISO 8601 형식).
  ///
  /// [scope] - 조회 범위: mine(내 일정만), shared(공유된 일정만), all(모두).
  ///
  /// [tagIds] - 태그 ID 리스트 (AND 방식: 모든 지정 태그를 포함한 일정만 반환).
  ///
  /// [groupIds] - 태그 그룹 ID 리스트 (해당 그룹의 태그를 가진 일정 반환).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/schedules')
  Future<List<ScheduleRead>> readSchedulesV1SchedulesGet({
    @Query('start_date') required DateTime startDate,
    @Query('end_date') required DateTime endDate,
    @Query('tag_ids') List<String>? tagIds,
    @Query('group_ids') List<String>? groupIds,
    @Query('timezone') String? timezone,
    @Query('scope') ResourceScope? scope = ResourceScope.mine,
    @DioOptions() RequestOptions? options,
  });

  /// Read Schedule.
  ///
  /// ID로 일정 조회 (공유된 일정 포함).
  ///
  /// 본인 소유 일정 또는 공유 접근 권한이 있는 일정을 조회합니다.
  /// 접근 권한이 없으면 403 Forbidden을 반환합니다.
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/schedules/{schedule_id}')
  Future<ScheduleRead> readScheduleV1SchedulesScheduleIdGet({
    @Path('schedule_id') required String scheduleId,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Update Schedule.
  ///
  /// 일정 업데이트 (반복 일정 인스턴스 포함).
  ///
  /// 일반 일정과 가상 인스턴스 모두 지원:.
  /// - 일반 일정: schedule_id로 조회하여 업데이트.
  /// - 가상 인스턴스: schedule_id를 parent_id로 사용하고 instance_start를 쿼리 파라미터로 전송.
  ///
  /// ### 요청 예시.
  /// ```json.
  /// {.
  ///     "title": "업데이트된 제목".
  /// }.
  /// ```.
  ///
  /// FastAPI Best Practices:.
  /// - Service는 session을 받아서 CRUD 직접 사용.
  /// - 가상 인스턴스인 경우 instance_start 쿼리 파라미터로 처리.
  ///
  /// [instanceStart] - 반복 일정 인스턴스 시작 시간 (ISO 8601 형식).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @PATCH('/v1/schedules/{schedule_id}')
  Future<ScheduleRead> updateScheduleV1SchedulesScheduleIdPatch({
    @Path('schedule_id') required String scheduleId,
    @Body() required ScheduleUpdate body,
    @Query('instance_start') DateTime? instanceStart,
    @Query('timezone') String? timezone,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Schedule.
  ///
  /// 일정 삭제 (반복 일정 인스턴스 포함).
  ///
  /// 일반 일정과 가상 인스턴스 모두 지원:.
  /// - 일반 일정: schedule_id로 조회하여 삭제.
  /// - 가상 인스턴스: schedule_id를 parent_id로 사용하고 instance_start를 쿼리 파라미터로 전송.
  ///
  /// FastAPI Best Practices:.
  /// - Service는 session을 받아서 CRUD 직접 사용.
  /// - 가상 인스턴스인 경우 instance_start 쿼리 파라미터로 처리.
  ///
  /// [instanceStart] - 반복 일정 인스턴스 시작 시간 (ISO 8601 형식).
  @DELETE('/v1/schedules/{schedule_id}')
  Future<void> deleteScheduleV1SchedulesScheduleIdDelete({
    @Path('schedule_id') required String scheduleId,
    @Query('instance_start') DateTime? instanceStart,
    @DioOptions() RequestOptions? options,
  });

  /// Get Schedule Timers.
  ///
  /// 일정의 모든 타이머 조회 (공유된 일정 포함).
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/schedules/{schedule_id}/timers')
  Future<List<TimerRead>> getScheduleTimersV1SchedulesScheduleIdTimersGet({
    @Path('schedule_id') required String scheduleId,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @DioOptions() RequestOptions? options,
  });

  /// Get Active Timer.
  ///
  /// 일정의 현재 활성 타이머 조회 (RUNNING 또는 PAUSED, 공유된 일정 포함).
  ///
  /// 활성 타이머가 없으면 404를 반환합니다.
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/schedules/{schedule_id}/timers/active')
  Future<TimerRead> getActiveTimerV1SchedulesScheduleIdTimersActiveGet({
    @Path('schedule_id') required String scheduleId,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @DioOptions() RequestOptions? options,
  });

  /// Create Todo From Schedule.
  ///
  /// 기존 Schedule에서 연관된 Todo 생성.
  ///
  /// Schedule의 정보를 기반으로 새로운 Todo를 생성합니다:.
  /// - Todo의 title, description은 Schedule에서 복사.
  /// - Todo의 deadline은 Schedule의 start_time으로 설정.
  /// - Schedule의 태그가 Todo에도 복사됨.
  /// - 생성된 Todo와 Schedule이 source_todo_id로 연결됨.
  ///
  /// 제약사항:.
  /// - 이미 Todo와 연결된 Schedule에서는 호출 불가 (400 에러).
  /// - tag_group_id는 필수 파라미터.
  ///
  /// :param schedule_id: Schedule ID.
  /// :param tag_group_id: Todo가 속할 TagGroup ID.
  /// :return: 생성된 Todo.
  ///
  /// [tagGroupId] - Todo가 속할 TagGroup ID (필수).
  @POST('/v1/schedules/{schedule_id}/todo')
  Future<void> createTodoFromScheduleV1SchedulesScheduleIdTodoPost({
    @Path('schedule_id') required String scheduleId,
    @Query('tag_group_id') required String tagGroupId,
    @DioOptions() RequestOptions? options,
  });
}
