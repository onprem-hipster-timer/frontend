//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:openapi_client/src/api_util.dart';
import 'package:openapi_client/src/model/http_validation_error.dart';
import 'package:openapi_client/src/model/resource_scope.dart';
import 'package:openapi_client/src/model/tag_include_mode.dart';
import 'package:openapi_client/src/model/timer_read.dart';
import 'package:openapi_client/src/model/timer_update.dart';

class TimersApi {

  final Dio _dio;

  final Serializers _serializers;

  const TimersApi(this._dio, this._serializers);

  /// Delete Timer
  /// 타이머 삭제
  ///
  /// Parameters:
  /// * [timerId] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [JsonObject] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<JsonObject>> deleteTimerV1TimersTimerIdDelete({ 
    required String timerId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/timers/{timer_id}'.replaceAll('{' r'timer_id' '}', encodeQueryParameter(_serializers, timerId, const FullType(String)).toString());
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

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
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

  /// Get Timer
  /// 타이머 조회 (공유된 타이머 포함)  본인 소유 타이머 또는 공유 접근 권한이 있는 타이머를 조회합니다. 접근 권한이 없으면 403 Forbidden을 반환합니다.
  ///
  /// Parameters:
  /// * [timerId] 
  /// * [includeSchedule] - Schedule 정보 포함 여부 (기본값: false)
  /// * [includeTodo] - Todo 정보 포함 여부 (기본값: false)
  /// * [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
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
  Future<Response<TimerRead>> getTimerV1TimersTimerIdGet({ 
    required String timerId,
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = none,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/timers/{timer_id}'.replaceAll('{' r'timer_id' '}', encodeQueryParameter(_serializers, timerId, const FullType(String)).toString());
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
      if (includeTodo != null) r'include_todo': encodeQueryParameter(_serializers, includeTodo, const FullType(bool)),
      if (tagIncludeMode != null) r'tag_include_mode': encodeQueryParameter(_serializers, tagIncludeMode, const FullType(TagIncludeMode)),
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

  /// Get User Active Timer
  /// 사용자의 현재 활성 타이머 조회 (RUNNING 또는 PAUSED)  활성 타이머가 없으면 404 반환 여러 개가 있으면 가장 최근 것 반환
  ///
  /// Parameters:
  /// * [includeSchedule] - Schedule 정보 포함 여부 (기본값: false)
  /// * [includeTodo] - Todo 정보 포함 여부 (기본값: false)
  /// * [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
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
  Future<Response<TimerRead>> getUserActiveTimerV1TimersActiveGet({ 
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = none,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/timers/active';
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
      if (includeTodo != null) r'include_todo': encodeQueryParameter(_serializers, includeTodo, const FullType(bool)),
      if (tagIncludeMode != null) r'tag_include_mode': encodeQueryParameter(_serializers, tagIncludeMode, const FullType(TagIncludeMode)),
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

  /// List Timers
  /// 타이머 목록 조회  조회 범위 (scope): - mine: 내 타이머만 (기본값) - shared: 공유된 타인의 타이머만 - all: 내 타이머 + 공유된 타이머  필터링 옵션: - status: 상태 필터 (RUNNING, PAUSED, COMPLETED, CANCELLED) - 복수 선택 가능 - type: 타입 필터   - independent: 독립 타이머 (schedule_id&#x3D;null AND todo_id&#x3D;null)   - schedule: Schedule 연결 타이머 (schedule_id !&#x3D; null)   - todo: Todo 연결 타이머 (todo_id !&#x3D; null) - start_date, end_date: 날짜 범위 필터 (started_at 기준)
  ///
  /// Parameters:
  /// * [scope] - 조회 범위: mine(내 타이머만), shared(공유된 타이머만), all(모두)
  /// * [status] - 상태 필터 (RUNNING, PAUSED, COMPLETED, CANCELLED) - 복수 선택 가능
  /// * [type] - 타입 필터: independent(독립 타이머), schedule(Schedule 연결), todo(Todo 연결)
  /// * [startDate] - 시작 날짜 필터 (started_at 기준, ISO 8601 형식)
  /// * [endDate] - 종료 날짜 필터 (started_at 기준, ISO 8601 형식)
  /// * [includeSchedule] - Schedule 정보 포함 여부 (기본값: false)
  /// * [includeTodo] - Todo 정보 포함 여부 (기본값: false)
  /// * [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
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
  Future<Response<BuiltList<TimerRead>>> listTimersV1TimersGet({ 
    ResourceScope? scope = mine,
    BuiltList<String>? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = none,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/timers';
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
      if (scope != null) r'scope': encodeQueryParameter(_serializers, scope, const FullType(ResourceScope)),
      r'status': encodeCollectionQueryParameter<String>(_serializers, status, const FullType(BuiltList, [FullType(String)]), format: ListFormat.multi,),
      r'type': encodeQueryParameter(_serializers, type, const FullType(String)),
      r'start_date': encodeQueryParameter(_serializers, startDate, const FullType(DateTime)),
      r'end_date': encodeQueryParameter(_serializers, endDate, const FullType(DateTime)),
      if (includeSchedule != null) r'include_schedule': encodeQueryParameter(_serializers, includeSchedule, const FullType(bool)),
      if (includeTodo != null) r'include_todo': encodeQueryParameter(_serializers, includeTodo, const FullType(bool)),
      if (tagIncludeMode != null) r'tag_include_mode': encodeQueryParameter(_serializers, tagIncludeMode, const FullType(TagIncludeMode)),
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

  /// Update Timer
  /// 타이머 메타데이터 업데이트 (title, description, tags)
  ///
  /// Parameters:
  /// * [timerId] 
  /// * [timerUpdate] 
  /// * [includeSchedule] - Schedule 정보 포함 여부 (기본값: false)
  /// * [includeTodo] - Todo 정보 포함 여부 (기본값: false)
  /// * [tagIncludeMode] - 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
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
  Future<Response<TimerRead>> updateTimerV1TimersTimerIdPatch({ 
    required String timerId,
    required TimerUpdate timerUpdate,
    bool? includeSchedule = false,
    bool? includeTodo = false,
    TagIncludeMode? tagIncludeMode = none,
    String? timezone,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/timers/{timer_id}'.replaceAll('{' r'timer_id' '}', encodeQueryParameter(_serializers, timerId, const FullType(String)).toString());
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
      if (includeSchedule != null) r'include_schedule': encodeQueryParameter(_serializers, includeSchedule, const FullType(bool)),
      if (includeTodo != null) r'include_todo': encodeQueryParameter(_serializers, includeTodo, const FullType(bool)),
      if (tagIncludeMode != null) r'tag_include_mode': encodeQueryParameter(_serializers, tagIncludeMode, const FullType(TagIncludeMode)),
      r'timezone': encodeQueryParameter(_serializers, timezone, const FullType(String)),
    };

    dynamic _bodyData;

    try {
      const _type = FullType(TimerUpdate);
      _bodyData = _serializers.serialize(timerUpdate, specifiedType: _type);

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

}
