# momeet_api.model.ScheduleCreate

## Load the model package
```dart
import 'package:momeet_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**title** | **String** |  | 
**description** | **String** |  | [optional] 
**startTime** | [**DateTime**](DateTime.md) |  | 
**endTime** | [**DateTime**](DateTime.md) |  | 
**recurrenceRule** | **String** |  | [optional] 
**recurrenceEnd** | [**DateTime**](DateTime.md) |  | [optional] 
**tagIds** | **BuiltList&lt;String&gt;** |  | [optional] 
**tagGroupId** | **String** |  | [optional] 
**sourceTodoId** | **String** |  | [optional] 
**state** | [**ScheduleState**](ScheduleState.md) |  | [optional] 
**createTodoOptions** | [**CreateTodoOptions**](CreateTodoOptions.md) |  | [optional] 
**visibility** | [**VisibilitySettings**](VisibilitySettings.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


