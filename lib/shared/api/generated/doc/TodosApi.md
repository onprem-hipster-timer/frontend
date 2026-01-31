# momeet_api.api.TodosApi

## Load the API package
```dart
import 'package:momeet_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createTodoV1TodosPost**](TodosApi.md#createtodov1todospost) | **POST** /v1/todos | Create Todo
[**deleteTodoV1TodosTodoIdDelete**](TodosApi.md#deletetodov1todostodoiddelete) | **DELETE** /v1/todos/{todo_id} | Delete Todo
[**getTodoActiveTimerV1TodosTodoIdTimersActiveGet**](TodosApi.md#gettodoactivetimerv1todostodoidtimersactiveget) | **GET** /v1/todos/{todo_id}/timers/active | Get Todo Active Timer
[**getTodoStatsV1TodosStatsGet**](TodosApi.md#gettodostatsv1todosstatsget) | **GET** /v1/todos/stats | Get Todo Stats
[**getTodoTimersV1TodosTodoIdTimersGet**](TodosApi.md#gettodotimersv1todostodoidtimersget) | **GET** /v1/todos/{todo_id}/timers | Get Todo Timers
[**readTodoV1TodosTodoIdGet**](TodosApi.md#readtodov1todostodoidget) | **GET** /v1/todos/{todo_id} | Read Todo
[**readTodosV1TodosGet**](TodosApi.md#readtodosv1todosget) | **GET** /v1/todos | Read Todos
[**updateTodoV1TodosTodoIdPatch**](TodosApi.md#updatetodov1todostodoidpatch) | **PATCH** /v1/todos/{todo_id} | Update Todo


# **createTodoV1TodosPost**
> TodoRead createTodoV1TodosPost(todoCreate)

Create Todo

새 Todo 생성  Todo는 독립적인 엔티티입니다. deadline이 있으면 별도의 Schedule이 자동으로 생성됩니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final TodoCreate todoCreate = ; // TodoCreate | 

try {
    final response = api.createTodoV1TodosPost(todoCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->createTodoV1TodosPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **todoCreate** | [**TodoCreate**](TodoCreate.md)|  | 

### Return type

[**TodoRead**](TodoRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteTodoV1TodosTodoIdDelete**
> JsonObject deleteTodoV1TodosTodoIdDelete(todoId)

Delete Todo

Todo 삭제

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final String todoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteTodoV1TodosTodoIdDelete(todoId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->deleteTodoV1TodosTodoIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **todoId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTodoActiveTimerV1TodosTodoIdTimersActiveGet**
> TimerRead getTodoActiveTimerV1TodosTodoIdTimersActiveGet(todoId, includeTodo, timezone)

Get Todo Active Timer

Todo의 현재 활성 타이머 조회 (RUNNING 또는 PAUSED, 공유된 Todo 포함)  활성 타이머가 없으면 404를 반환합니다. Schedule의 /schedules/{schedule_id}/timers/active 엔드포인트와 동일한 패턴입니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final String todoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final bool includeTodo = true; // bool | Todo 정보 포함 여부 (기본값: false)
final String timezone = timezone_example; // String | 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환

try {
    final response = api.getTodoActiveTimerV1TodosTodoIdTimersActiveGet(todoId, includeTodo, timezone);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->getTodoActiveTimerV1TodosTodoIdTimersActiveGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **todoId** | **String**|  | 
 **includeTodo** | **bool**| Todo 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **timezone** | **String**| 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환 | [optional] 

### Return type

[**TimerRead**](TimerRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTodoStatsV1TodosStatsGet**
> TodoStats getTodoStatsV1TodosStatsGet(groupId)

Get Todo Stats

Todo 통계 조회  그룹별 태그 통계를 반환합니다. group_id가 지정되면 해당 그룹의 태그만 집계합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final String groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 필터링할 태그 그룹 ID

try {
    final response = api.getTodoStatsV1TodosStatsGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->getTodoStatsV1TodosStatsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**| 필터링할 태그 그룹 ID | [optional] 

### Return type

[**TodoStats**](TodoStats.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTodoTimersV1TodosTodoIdTimersGet**
> BuiltList<TimerRead> getTodoTimersV1TodosTodoIdTimersGet(todoId, includeTodo, timezone)

Get Todo Timers

Todo의 모든 타이머 조회 (공유된 Todo 포함)  Schedule의 /schedules/{schedule_id}/timers 엔드포인트와 동일한 패턴입니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final String todoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final bool includeTodo = true; // bool | Todo 정보 포함 여부 (기본값: false)
final String timezone = timezone_example; // String | 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환

try {
    final response = api.getTodoTimersV1TodosTodoIdTimersGet(todoId, includeTodo, timezone);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->getTodoTimersV1TodosTodoIdTimersGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **todoId** | **String**|  | 
 **includeTodo** | **bool**| Todo 정보 포함 여부 (기본값: false) | [optional] [default to false]
 **timezone** | **String**| 타임존 (예: UTC, +09:00, Asia/Seoul). 지정하지 않으면 UTC로 반환 | [optional] 

### Return type

[**BuiltList&lt;TimerRead&gt;**](TimerRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readTodoV1TodosTodoIdGet**
> TodoRead readTodoV1TodosTodoIdGet(todoId)

Read Todo

ID로 Todo 조회 (공유된 Todo 포함)  본인 소유 Todo 또는 공유 접근 권한이 있는 Todo를 조회합니다. 접근 권한이 없으면 403 Forbidden을 반환합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final String todoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.readTodoV1TodosTodoIdGet(todoId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->readTodoV1TodosTodoIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **todoId** | **String**|  | 

### Return type

[**TodoRead**](TodoRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readTodosV1TodosGet**
> BuiltList<TodoRead> readTodosV1TodosGet(scope, tagIds, groupIds)

Read Todos

Todo 목록 조회 (태그/그룹 필터링 지원)  조회 범위 (scope): - mine: 내 Todo만 (기본값) - shared: 공유된 타인의 Todo만 - all: 내 Todo + 공유된 Todo  그룹 필터링: - group_ids: 해당 그룹에 속한 Todo 반환   - tag_group_id로 직접 연결된 Todo   - OR 해당 그룹의 태그를 가진 Todo  태그 필터링: - tag_ids: AND 방식 (모든 지정 태그를 포함한 Todo만 반환) - 태그 필터 시 조상 노드도 포함 (orphan 방지)  응답의 include_reason 필드: - MATCH: 필터 조건에 직접 매칭된 Todo - ANCESTOR: 매칭된 Todo의 조상이라 포함된 Todo  둘 다 지정 시: 그룹 필터링 후 태그 필터링 적용

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final ResourceScope scope = ; // ResourceScope | 조회 범위: mine(내 Todo만), shared(공유된 Todo만), all(모두)
final BuiltList<String> tagIds = ; // BuiltList<String> | 태그 ID 리스트 (AND 방식: 모든 지정 태그를 포함한 Todo만 반환)
final BuiltList<String> groupIds = ; // BuiltList<String> | 태그 그룹 ID 리스트 (해당 그룹에 속한 Todo 반환 - 직접 연결 또는 태그 기반)

try {
    final response = api.readTodosV1TodosGet(scope, tagIds, groupIds);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->readTodosV1TodosGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **scope** | [**ResourceScope**](.md)| 조회 범위: mine(내 Todo만), shared(공유된 Todo만), all(모두) | [optional] [default to mine]
 **tagIds** | [**BuiltList&lt;String&gt;**](String.md)| 태그 ID 리스트 (AND 방식: 모든 지정 태그를 포함한 Todo만 반환) | [optional] 
 **groupIds** | [**BuiltList&lt;String&gt;**](String.md)| 태그 그룹 ID 리스트 (해당 그룹에 속한 Todo 반환 - 직접 연결 또는 태그 기반) | [optional] 

### Return type

[**BuiltList&lt;TodoRead&gt;**](TodoRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTodoV1TodosTodoIdPatch**
> TodoRead updateTodoV1TodosTodoIdPatch(todoId, todoUpdate)

Update Todo

Todo 업데이트  title, description, tag_ids, deadline, parent_id, status를 업데이트할 수 있습니다.  deadline 변경 시: - deadline 추가: 새 Schedule 생성 - deadline 변경: 기존 Schedule 업데이트 - deadline 제거: 기존 Schedule 삭제

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getTodosApi();
final String todoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final TodoUpdate todoUpdate = ; // TodoUpdate | 

try {
    final response = api.updateTodoV1TodosTodoIdPatch(todoId, todoUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TodosApi->updateTodoV1TodosTodoIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **todoId** | **String**|  | 
 **todoUpdate** | [**TodoUpdate**](TodoUpdate.md)|  | 

### Return type

[**TodoRead**](TodoRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

