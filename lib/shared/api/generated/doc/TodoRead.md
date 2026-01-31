# openapi_client.model.TodoRead

## Load the model package
```dart
import 'package:openapi_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | 
**title** | **String** |  | 
**description** | **String** |  | [optional] 
**deadline** | [**DateTime**](DateTime.md) |  | [optional] 
**tagGroupId** | **String** |  | 
**parentId** | **String** |  | [optional] 
**status** | [**TodoStatus**](TodoStatus.md) |  | 
**createdAt** | [**DateTime**](DateTime.md) |  | 
**tags** | [**BuiltList&lt;TagRead&gt;**](TagRead.md) |  | [optional] [default to ListBuilder()]
**schedules** | [**BuiltList&lt;ScheduleRead&gt;**](ScheduleRead.md) |  | [optional] [default to ListBuilder()]
**includeReason** | [**TodoIncludeReason**](TodoIncludeReason.md) |  | [optional] [default to TodoIncludeReason.MATCH]
**ownerId** | **String** |  | [optional] 
**visibilityLevel** | [**VisibilityLevel**](VisibilityLevel.md) |  | [optional] 
**isShared** | **bool** |  | [optional] [default to false]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


