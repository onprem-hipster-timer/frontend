# momeet_api.model.TimerRead

## Load the model package
```dart
import 'package:momeet_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**scheduleId** | **String** |  | [optional] 
**todoId** | **String** |  | [optional] 
**title** | **String** |  | [optional] 
**description** | **String** |  | [optional] 
**allocatedDuration** | **int** |  | 
**elapsedTime** | **int** |  | 
**status** | **String** |  | 
**startedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**pausedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**endedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**updatedAt** | [**DateTime**](DateTime.md) |  | 
**pauseHistory** | [**BuiltList&lt;BuiltMap&lt;String, JsonObject&gt;&gt;**](BuiltMap.md) |  | [optional] [default to ListBuilder()]
**schedule** | [**ScheduleRead**](ScheduleRead.md) |  | [optional] 
**todo** | [**TodoRead**](TodoRead.md) |  | [optional] 
**tags** | [**BuiltList&lt;TagRead&gt;**](TagRead.md) |  | [optional] [default to ListBuilder()]
**ownerId** | **String** |  | [optional] 
**visibilityLevel** | [**VisibilityLevel**](VisibilityLevel.md) |  | [optional] 
**isShared** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


