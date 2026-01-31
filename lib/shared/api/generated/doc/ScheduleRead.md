# momeet_api.model.ScheduleRead

## Load the model package
```dart
import 'package:momeet_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**title** | **String** |  | 
**description** | **String** |  | [optional] 
**startTime** | [**DateTime**](DateTime.md) |  | 
**endTime** | [**DateTime**](DateTime.md) |  | 
**recurrenceRule** | **String** |  | [optional] 
**recurrenceEnd** | [**DateTime**](DateTime.md) |  | [optional] 
**parentId** | **String** |  | [optional] 
**tagGroupId** | **String** |  | [optional] 
**sourceTodoId** | **String** |  | [optional] 
**state** | [**ScheduleState**](ScheduleState.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**tags** | [**BuiltList&lt;TagRead&gt;**](TagRead.md) |  | [optional] [default to ListBuilder()]
**ownerId** | **String** |  | [optional] 
**visibilityLevel** | [**VisibilityLevel**](VisibilityLevel.md) |  | [optional] 
**isShared** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


