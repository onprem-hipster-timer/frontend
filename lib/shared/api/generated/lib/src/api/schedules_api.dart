//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:momeet_api/src/api_util.dart';
import 'package:momeet_api/src/model/http_validation_error.dart';
import 'package:momeet_api/src/model/resource_scope.dart';
import 'package:momeet_api/src/model/schedule_create.dart';
import 'package:momeet_api/src/model/schedule_read.dart';
import 'package:momeet_api/src/model/schedule_update.dart';
import 'package:momeet_api/src/model/timer_read.dart';

class SchedulesApi {

  final Dio _dio;

  final Serializers _serializers;

  const SchedulesApi(this._dio, this._serializers);

  /// Create Schedule
  /// 새 일정 생성  FastAPI Best Practices: - async 라우트 사용 - 트랜잭션 자동 관리 (context manager) - Exception Handler가 예외 처리
  ///
  /// Parameters:
  /// * [scheduleCreate] 
  /// * [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [ScheduleRead] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ScheduleRead>> createScheduleV1SchedulesPost({ 
    required ScheduleCreate scheduleCreate,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'timezone': encodeQueryParameter(_serializers, timezone, const FullType(String)),
    };

    dynamic _bodyData;

    try {
      const _type = FullType(ScheduleCreate);
      _bodyData = _serializers.serialize(scheduleCreate, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
          queryParameters: _queryParameters,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    ScheduleRead? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(ScheduleRead),
      ) as ScheduleRead;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<ScheduleRead>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Create Todo From Schedule
  /// 기존 Schedule에서 연관된 Todo 생성  Schedule의 정보를 기반으로 새로운 Todo를 생성합니다: - Todo의 title, description은 Schedule에서 복사 - Todo의 deadline은 Schedule의 start_time으로 설정 - Schedule의 태그가 Todo에도 복사됨 - 생성된 Todo와 Schedule이 source_todo_id로 연결됨  제약사항: - 이미 Todo와 연결된 Schedule에서는 호출 불가 (400 에러) - tag_group_id는 필수 파라미터  :param schedule_id: Schedule ID :param tag_group_id: Todo가 속할 TagGroup ID :return: 생성된 Todo
  ///
  /// Parameters:
  /// * [scheduleId] 
  /// * [tagGroupId] - Todo가 속할 TagGroup ID (필수)
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [JsonObject] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<JsonObject>> createTodoFromScheduleV1SchedulesScheduleIdTodoPost({ 
    required String scheduleId,
    required String tagGroupId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules/{schedule_id}/todo'.replaceAll('{' r'schedule_id' '}', encodeQueryParameter(_serializers, scheduleId, const FullType(String)).toString());
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'tag_group_id': encodeQueryParameter(_serializers, tagGroupId, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    JsonObject? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(JsonObject),
      ) as JsonObject;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<JsonObject>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Delete Schedule
  /// 일정 삭제 (반복 일정 인스턴스 포함)  일반 일정과 가상 인스턴스 모두 지원: - 일반 일정: schedule_id로 조회하여 삭제 - 가상 인스턴스: schedule_id를 parent_id로 사용하고 instance_start를 쿼리 파라미터로 전송  FastAPI Best Practices: - Service는 session을 받아서 CRUD 직접 사용 - 가상 인스턴스인 경우 instance_start 쿼리 파라미터로 처리
  ///
  /// Parameters:
  /// * [scheduleId] 
  /// * [instanceStart] - 반복 일정 인스턴스 시작 시간 (ISO 8601 형식)
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [JsonObject] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<JsonObject>> deleteScheduleV1SchedulesScheduleIdDelete({ 
    required String scheduleId,
    DateTime? instanceStart,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules/{schedule_id}'.replaceAll('{' r'schedule_id' '}', encodeQueryParameter(_serializers, scheduleId, const FullType(String)).toString());
    final _options = Options(
      method: r'DELETE',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'instance_start': encodeQueryParameter(_serializers, instanceStart, const FullType(DateTime)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    JsonObject? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(JsonObject),
      ) as JsonObject;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<JsonObject>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Get Active Timer
  /// 일정의 현재 활성 타이머 조회 (RUNNING 또는 PAUSED, 공유된 일정 포함)  활성 타이머가 없으면 404를 반환합니다.
  ///
  /// Parameters:
  /// * [scheduleId] 
  /// * [includeSchedule] - Schedule 정보 포함 여부 (기본값: false)
  /// * [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [TimerRead] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TimerRead>> getActiveTimerV1SchedulesScheduleIdTimersActiveGet({ 
    required String scheduleId,
    bool? includeSchedule = false,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules/{schedule_id}/timers/active'.replaceAll('{' r'schedule_id' '}', encodeQueryParameter(_serializers, scheduleId, const FullType(String)).toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (includeSchedule != null) r'include_schedule': encodeQueryParameter(_serializers, includeSchedule, const FullType(bool)),
      r'timezone': encodeQueryParameter(_serializers, timezone, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    TimerRead? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(TimerRead),
      ) as TimerRead;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<TimerRead>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Get Schedule Timers
  /// 일정의 모든 타이머 조회 (공유된 일정 포함)
  ///
  /// Parameters:
  /// * [scheduleId] 
  /// * [includeSchedule] - Schedule 정보 포함 여부 (기본값: false)
  /// * [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BuiltList<TimerRead>] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BuiltList<TimerRead>>> getScheduleTimersV1SchedulesScheduleIdTimersGet({ 
    required String scheduleId,
    bool? includeSchedule = false,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules/{schedule_id}/timers'.replaceAll('{' r'schedule_id' '}', encodeQueryParameter(_serializers, scheduleId, const FullType(String)).toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      if (includeSchedule != null) r'include_schedule': encodeQueryParameter(_serializers, includeSchedule, const FullType(bool)),
      r'timezone': encodeQueryParameter(_serializers, timezone, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BuiltList<TimerRead>? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BuiltList, [FullType(TimerRead)]),
      ) as BuiltList<TimerRead>;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BuiltList<TimerRead>>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Read Schedule
  /// ID로 일정 조회 (공유된 일정 포함)  본인 소유 일정 또는 공유 접근 권한이 있는 일정을 조회합니다. 접근 권한이 없으면 403 Forbidden을 반환합니다.
  ///
  /// Parameters:
  /// * [scheduleId] 
  /// * [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [ScheduleRead] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ScheduleRead>> readScheduleV1SchedulesScheduleIdGet({ 
    required String scheduleId,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules/{schedule_id}'.replaceAll('{' r'schedule_id' '}', encodeQueryParameter(_serializers, scheduleId, const FullType(String)).toString());
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'timezone': encodeQueryParameter(_serializers, timezone, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    ScheduleRead? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(ScheduleRead),
      ) as ScheduleRead;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<ScheduleRead>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Read Schedules
  /// 날짜 범위 기반 일정 조회 (반복 일정 포함, 태그 필터링 지원)  조회 범위 (scope): - mine: 내 일정만 (기본값) - shared: 공유된 타인의 일정만 - all: 내 일정 + 공유된 일정  날짜 범위: - start_date: 조회 시작 날짜/시간 (필수) - end_date: 조회 종료 날짜/시간 (필수) - 지정된 날짜 범위와 겹치는 모든 일정을 반환 (반복 일정은 가상 인스턴스로 확장)  태그 필터링: - tag_ids: AND 방식 (모든 지정 태그를 포함한 일정만 반환) - group_ids: 해당 그룹의 태그 중 하나라도 있는 일정 반환 - 둘 다 지정 시: 그룹 필터링 후 태그 필터링 적용  FastAPI Best Practices: - async 라우트 사용
  ///
  /// Parameters:
  /// * [startDate] - 조회 시작 날짜/시간 (ISO 8601 형식)
  /// * [endDate] - 조회 종료 날짜/시간 (ISO 8601 형식)
  /// * [scope] - 조회 범위: mine(내 일정만), shared(공유된 일정만), all(모두)
  /// * [tagIds] - 태그 ID 리스트 (AND 방식: 모든 지정 태그를 포함한 일정만 반환)
  /// * [groupIds] - 태그 그룹 ID 리스트 (해당 그룹의 태그를 가진 일정 반환)
  /// * [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BuiltList<ScheduleRead>] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BuiltList<ScheduleRead>>> readSchedulesV1SchedulesGet({ 
    required DateTime startDate,
    required DateTime endDate,
    ResourceScope? scope = ResourceScope.mine,
    BuiltList<String>? tagIds,
    BuiltList<String>? groupIds,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'start_date': encodeQueryParameter(_serializers, startDate, const FullType(DateTime)),
      r'end_date': encodeQueryParameter(_serializers, endDate, const FullType(DateTime)),
      if (scope != null) r'scope': encodeQueryParameter(_serializers, scope, const FullType(ResourceScope)),
      r'tag_ids': encodeCollectionQueryParameter<String>(_serializers, tagIds, const FullType(BuiltList, [FullType(String)]), format: ListFormat.multi,),
      r'group_ids': encodeCollectionQueryParameter<String>(_serializers, groupIds, const FullType(BuiltList, [FullType(String)]), format: ListFormat.multi,),
      r'timezone': encodeQueryParameter(_serializers, timezone, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BuiltList<ScheduleRead>? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BuiltList, [FullType(ScheduleRead)]),
      ) as BuiltList<ScheduleRead>;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BuiltList<ScheduleRead>>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Update Schedule
  /// 일정 업데이트 (반복 일정 인스턴스 포함)  일반 일정과 가상 인스턴스 모두 지원: - 일반 일정: schedule_id로 조회하여 업데이트 - 가상 인스턴스: schedule_id를 parent_id로 사용하고 instance_start를 쿼리 파라미터로 전송  ### 요청 예시 &#x60;&#x60;&#x60;json {     \&quot;title\&quot;: \&quot;업데이트된 제목\&quot; } &#x60;&#x60;&#x60;  FastAPI Best Practices: - Service는 session을 받아서 CRUD 직접 사용 - 가상 인스턴스인 경우 instance_start 쿼리 파라미터로 처리
  ///
  /// Parameters:
  /// * [scheduleId] 
  /// * [scheduleUpdate] 
  /// * [instanceStart] - 반복 일정 인스턴스 시작 시간 (ISO 8601 형식)
  /// * [timezone] - 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [ScheduleRead] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ScheduleRead>> updateScheduleV1SchedulesScheduleIdPatch({ 
    required String scheduleId,
    required ScheduleUpdate scheduleUpdate,
    DateTime? instanceStart,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/schedules/{schedule_id}'.replaceAll('{' r'schedule_id' '}', encodeQueryParameter(_serializers, scheduleId, const FullType(String)).toString());
    final _options = Options(
      method: r'PATCH',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'HTTPBearer',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'instance_start': encodeQueryParameter(_serializers, instanceStart, const FullType(DateTime)),
      r'timezone': encodeQueryParameter(_serializers, timezone, const FullType(String)),
    };

    dynamic _bodyData;

    try {
      const _type = FullType(ScheduleUpdate);
      _bodyData = _serializers.serialize(scheduleUpdate, specifiedType: _type);

    } catch(error, stackTrace) {
      throw DioException(
         requestOptions: _options.compose(
          _dio.options,
          _path,
          queryParameters: _queryParameters,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    ScheduleRead? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(ScheduleRead),
      ) as ScheduleRead;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<ScheduleRead>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
