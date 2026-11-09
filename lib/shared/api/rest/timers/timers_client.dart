// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/resource_scope.dart';
import '../models/tag_include_mode.dart';
import '../models/timer_create.dart';
import '../models/timer_read.dart';
import '../models/timer_update.dart';

part 'timers_client.g.dart';

@RestApi()
abstract class TimersClient {
  factory TimersClient(Dio dio, {String? baseUrl}) = _TimersClient;

  /// Create Timer.
  ///
  /// 새 타이머 생성 및 시작.
  ///
  /// schedule_id, todo_id 모두 Optional:.
  /// - 둘 다 없으면: 독립 타이머.
  /// - schedule_id만: Schedule에 연결된 타이머.
  /// - todo_id만: Todo에 연결된 타이머.
  /// - 둘 다 있으면: Schedule과 Todo 모두에 연결된 타이머.
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/timers')
  Future<TimerRead> createTimerV1TimersPost({
    @Body() required TimerCreate body,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// List Timers.
  ///
  /// 타이머 목록 조회.
  ///
  /// 조회 범위 (scope):.
  /// - mine: 내 타이머만 (기본값).
  /// - shared: 공유된 타인의 타이머만.
  /// - all: 내 타이머 + 공유된 타이머.
  ///
  /// 필터링 옵션:.
  /// - status: 상태 필터 (RUNNING, PAUSED, COMPLETED, CANCELLED) - 복수 선택 가능.
  /// - type: 타입 필터.
  ///   - independent: 독립 타이머 (schedule_id=null AND todo_id=null).
  ///   - schedule: Schedule 연결 타이머 (schedule_id != null).
  ///   - todo: Todo 연결 타이머 (todo_id != null).
  /// - start_date, end_date: 날짜 범위 필터 (started_at 기준).
  ///
  /// [scope] - 조회 범위: mine(내 타이머만), shared(공유된 타이머만), all(모두).
  ///
  /// [status] - 상태 필터 (RUNNING, PAUSED, COMPLETED, CANCELLED) - 복수 선택 가능.
  ///
  /// [type] - 타입 필터: independent(독립 타이머), schedule(Schedule 연결), todo(Todo 연결).
  ///
  /// [startDate] - 시작 날짜 필터 (started_at 기준, ISO 8601 형식).
  ///
  /// [endDate] - 종료 날짜 필터 (started_at 기준, ISO 8601 형식).
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/timers')
  Future<List<TimerRead>> listTimersV1TimersGet({
    @Query('status') List<String>? status,
    @Query('type') String? type,
    @Query('start_date') DateTime? startDate,
    @Query('end_date') DateTime? endDate,
    @Query('timezone') String? timezone,
    @Query('scope') ResourceScope? scope = ResourceScope.mine,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// Get User Active Timer.
  ///
  /// 사용자의 현재 활성 타이머 조회 (RUNNING 또는 PAUSED).
  ///
  /// 활성 타이머가 없으면 404 반환.
  /// 여러 개가 있으면 가장 최근 것 반환.
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/timers/active')
  Future<TimerRead> getUserActiveTimerV1TimersActiveGet({
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// Get Timer.
  ///
  /// 타이머 조회 (공유된 타이머 포함).
  ///
  /// 본인 소유 타이머 또는 공유 접근 권한이 있는 타이머를 조회합니다.
  /// 접근 권한이 없으면 403 Forbidden을 반환합니다.
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @GET('/v1/timers/{timer_id}')
  Future<TimerRead> getTimerV1TimersTimerIdGet({
    @Path('timer_id') required String timerId,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// Update Timer.
  ///
  /// 타이머 메타데이터 업데이트 (title, description, tags, todo_id, schedule_id, allocated_duration).
  ///
  /// allocated_duration은 현재 경과 시간(실행 중이면 지금까지 실행한 구간 포함)보다 커야 한다 (아니면 422). 만료된 타이머는 늘린 뒤 재개할 수 있다.
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @PATCH('/v1/timers/{timer_id}')
  Future<TimerRead> updateTimerV1TimersTimerIdPatch({
    @Path('timer_id') required String timerId,
    @Body() required TimerUpdate body,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// Delete Timer.
  ///
  /// 타이머 삭제.
  @DELETE('/v1/timers/{timer_id}')
  Future<void> deleteTimerV1TimersTimerIdDelete({
    @Path('timer_id') required String timerId,
    @DioOptions() RequestOptions? options,
  });

  /// Pause Timer.
  ///
  /// 타이머 일시정지 (RUNNING → PAUSED).
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @PATCH('/v1/timers/{timer_id}/pause')
  Future<TimerRead> pauseTimerV1TimersTimerIdPausePatch({
    @Path('timer_id') required String timerId,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// Resume Timer.
  ///
  /// 타이머 재개 (PAUSED → RUNNING).
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @PATCH('/v1/timers/{timer_id}/resume')
  Future<TimerRead> resumeTimerV1TimersTimerIdResumePatch({
    @Path('timer_id') required String timerId,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// Stop Timer.
  ///
  /// 타이머 종료 (RUNNING·PAUSED → COMPLETED).
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/timers/{timer_id}/stop')
  Future<TimerRead> stopTimerV1TimersTimerIdStopPost({
    @Path('timer_id') required String timerId,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });

  /// Cancel Timer.
  ///
  /// 타이머 취소 (RUNNING·PAUSED → CANCELLED).
  ///
  /// [includeSchedule] - Schedule 정보 포함 여부 (기본값: false).
  ///
  /// [includeTodo] - Todo 정보 포함 여부 (기본값: false).
  ///
  /// [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속).
  ///
  /// [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환.
  @POST('/v1/timers/{timer_id}/cancel')
  Future<TimerRead> cancelTimerV1TimersTimerIdCancelPost({
    @Path('timer_id') required String timerId,
    @Query('timezone') String? timezone,
    @Query('include_schedule') bool? includeSchedule = false,
    @Query('include_todo') bool? includeTodo = false,
    @Query('tag_include_mode')
    TagIncludeMode? tagIncludeMode = TagIncludeMode.none,
    @DioOptions() RequestOptions? options,
  });
}
