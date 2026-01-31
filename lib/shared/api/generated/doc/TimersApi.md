# openapi_client.api.TimersApi

## Load the API package
```dart
import 'package:openapi_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteTimerV1TimersTimerIdDelete**](TimersApi.md#deletetimerv1timerstimeriddelete) | **DELETE** /v1/timers/{timer_id} | Delete Timer
[**getTimerV1TimersTimerIdGet**](TimersApi.md#gettimerv1timerstimeridget) | **GET** /v1/timers/{timer_id} | Get Timer
[**getUserActiveTimerV1TimersActiveGet**](TimersApi.md#getuseractivetimerv1timersactiveget) | **GET** /v1/timers/active | Get User Active Timer
[**listTimersV1TimersGet**](TimersApi.md#listtimersv1timersget) | **GET** /v1/timers | List Timers
[**updateTimerV1TimersTimerIdPatch**](TimersApi.md#updatetimerv1timerstimeridpatch) | **PATCH** /v1/timers/{timer_id} | Update Timer


# **deleteTimerV1TimersTimerIdDelete**
> JsonObject deleteTimerV1TimersTimerIdDelete(timerId)

Delete Timer

타이머 삭제

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTimersApi();
final String timerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteTimerV1TimersTimerIdDelete(timerId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimersApi->deleteTimerV1TimersTimerIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **timerId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTimerV1TimersTimerIdGet**
> TimerRead getTimerV1TimersTimerIdGet(timerId, includeSchedule, includeTodo, tagIncludeMode, timezone)

Get Timer

타이머 조회 (공유된 타이머 포함)  본인 소유 타이머 또는 공유 접근 권한이 있는 타이머를 조회합니다. 접근 권한이 없으면 403 Forbidden을 반환합니다.

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTimersApi();
final String timerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final bool includeSchedule = true; // bool | Schedule 정보 포함 여부 (기본값: false)
final bool includeTodo = true; // bool | Todo 정보 포함 여부 (기본값: false)
final TagIncludeMode tagIncludeMode = ; // TagIncludeMode | 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
final String timezone = timezone_example; // String | 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환

try {
    final response = api.getTimerV1TimersTimerIdGet(timerId, includeSchedule, includeTodo, tagIncludeMode, timezone);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimersApi->getTimerV1TimersTimerIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **timerId** | **String**|  | 
 **includeSchedule** | **bool**| Schedule 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **includeTodo** | **bool**| Todo 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **tagIncludeMode** | [**TagIncludeMode**](.md)| 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속) | [optional] [default to none]
 **timezone** | **String**| 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환 | [optional] 

### Return type

[**TimerRead**](TimerRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserActiveTimerV1TimersActiveGet**
> TimerRead getUserActiveTimerV1TimersActiveGet(includeSchedule, includeTodo, tagIncludeMode, timezone)

Get User Active Timer

사용자의 현재 활성 타이머 조회 (RUNNING 또는 PAUSED)  활성 타이머가 없으면 404 반환 여러 개가 있으면 가장 최근 것 반환

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTimersApi();
final bool includeSchedule = true; // bool | Schedule 정보 포함 여부 (기본값: false)
final bool includeTodo = true; // bool | Todo 정보 포함 여부 (기본값: false)
final TagIncludeMode tagIncludeMode = ; // TagIncludeMode | 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
final String timezone = timezone_example; // String | 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환

try {
    final response = api.getUserActiveTimerV1TimersActiveGet(includeSchedule, includeTodo, tagIncludeMode, timezone);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimersApi->getUserActiveTimerV1TimersActiveGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **includeSchedule** | **bool**| Schedule 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **includeTodo** | **bool**| Todo 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **tagIncludeMode** | [**TagIncludeMode**](.md)| 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속) | [optional] [default to none]
 **timezone** | **String**| 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환 | [optional] 

### Return type

[**TimerRead**](TimerRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTimersV1TimersGet**
> BuiltList<TimerRead> listTimersV1TimersGet(scope, status, type, startDate, endDate, includeSchedule, includeTodo, tagIncludeMode, timezone)

List Timers

타이머 목록 조회  조회 범위 (scope): - mine: 내 타이머만 (기본값) - shared: 공유된 타인의 타이머만 - all: 내 타이머 + 공유된 타이머  필터링 옵션: - status: 상태 필터 (RUNNING, PAUSED, COMPLETED, CANCELLED) - 복수 선택 가능 - type: 타입 필터   - independent: 독립 타이머 (schedule_id=null AND todo_id=null)   - schedule: Schedule 연결 타이머 (schedule_id != null)   - todo: Todo 연결 타이머 (todo_id != null) - start_date, end_date: 날짜 범위 필터 (started_at 기준)

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTimersApi();
final ResourceScope scope = ; // ResourceScope | 조회 범위: mine(내 타이머만), shared(공유된 타이머만), all(모두)
final BuiltList<String> status = ; // BuiltList<String> | 상태 필터 (RUNNING, PAUSED, COMPLETED, CANCELLED) - 복수 선택 가능
final String type = type_example; // String | 타입 필터: independent(독립 타이머), schedule(Schedule 연결), todo(Todo 연결)
final DateTime startDate = 2013-10-20T19:20:30+01:00; // DateTime | 시작 날짜 필터 (started_at 기준, ISO 8601 형식)
final DateTime endDate = 2013-10-20T19:20:30+01:00; // DateTime | 종료 날짜 필터 (started_at 기준, ISO 8601 형식)
final bool includeSchedule = true; // bool | Schedule 정보 포함 여부 (기본값: false)
final bool includeTodo = true; // bool | Todo 정보 포함 여부 (기본값: false)
final TagIncludeMode tagIncludeMode = ; // TagIncludeMode | 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
final String timezone = timezone_example; // String | 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환

try {
    final response = api.listTimersV1TimersGet(scope, status, type, startDate, endDate, includeSchedule, includeTodo, tagIncludeMode, timezone);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimersApi->listTimersV1TimersGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | [**ResourceScope**](.md)| 조회 범위: mine(내 타이머만), shared(공유된 타이머만), all(모두) | [optional] [default to mine]
 **status** | [**BuiltList&lt;String&gt;**](String.md)| 상태 필터 (RUNNING, PAUSED, COMPLETED, CANCELLED) - 복수 선택 가능 | [optional] 
 **type** | **String**| 타입 필터: independent(독립 타이머), schedule(Schedule 연결), todo(Todo 연결) | [optional] 
 **startDate** | **DateTime**| 시작 날짜 필터 (started_at 기준, ISO 8601 형식) | [optional] 
 **endDate** | **DateTime**| 종료 날짜 필터 (started_at 기준, ISO 8601 형식) | [optional] 
 **includeSchedule** | **bool**| Schedule 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **includeTodo** | **bool**| Todo 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **tagIncludeMode** | [**TagIncludeMode**](.md)| 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속) | [optional] [default to none]
 **timezone** | **String**| 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환 | [optional] 

### Return type

[**BuiltList&lt;TimerRead&gt;**](TimerRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTimerV1TimersTimerIdPatch**
> TimerRead updateTimerV1TimersTimerIdPatch(timerId, timerUpdate, includeSchedule, includeTodo, tagIncludeMode, timezone)

Update Timer

타이머 메타데이터 업데이트 (title, description, tags)

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTimersApi();
final String timerId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final TimerUpdate timerUpdate = ; // TimerUpdate | 
final bool includeSchedule = true; // bool | Schedule 정보 포함 여부 (기본값: false)
final bool includeTodo = true; // bool | Todo 정보 포함 여부 (기본값: false)
final TagIncludeMode tagIncludeMode = ; // TagIncludeMode | 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속)
final String timezone = timezone_example; // String | 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환

try {
    final response = api.updateTimerV1TimersTimerIdPatch(timerId, timerUpdate, includeSchedule, includeTodo, tagIncludeMode, timezone);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimersApi->updateTimerV1TimersTimerIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **timerId** | **String**|  | 
 **timerUpdate** | [**TimerUpdate**](TimerUpdate.md)|  | 
 **includeSchedule** | **bool**| Schedule 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **includeTodo** | **bool**| Todo 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **tagIncludeMode** | [**TagIncludeMode**](.md)| 태그 포함 모드: none(포함 안 함), timer_only(타이머 태그만), inherit_from_schedule(스케줄/Todo 태그 상속) | [optional] [default to none]
 **timezone** | **String**| 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환 | [optional] 

### Return type

[**TimerRead**](TimerRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

