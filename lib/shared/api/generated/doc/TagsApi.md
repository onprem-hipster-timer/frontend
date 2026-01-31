# openapi_client.api.TagsApi

## Load the API package
```dart
import 'package:openapi_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createTagGroupV1TagsGroupsPost**](TagsApi.md#createtaggroupv1tagsgroupspost) | **POST** /v1/tags/groups | Create Tag Group
[**createTagV1TagsPost**](TagsApi.md#createtagv1tagspost) | **POST** /v1/tags | Create Tag
[**deleteTagGroupV1TagsGroupsGroupIdDelete**](TagsApi.md#deletetaggroupv1tagsgroupsgroupiddelete) | **DELETE** /v1/tags/groups/{group_id} | Delete Tag Group
[**deleteTagV1TagsTagIdDelete**](TagsApi.md#deletetagv1tagstagiddelete) | **DELETE** /v1/tags/{tag_id} | Delete Tag
[**readTagGroupV1TagsGroupsGroupIdGet**](TagsApi.md#readtaggroupv1tagsgroupsgroupidget) | **GET** /v1/tags/groups/{group_id} | Read Tag Group
[**readTagGroupsV1TagsGroupsGet**](TagsApi.md#readtaggroupsv1tagsgroupsget) | **GET** /v1/tags/groups | Read Tag Groups
[**readTagV1TagsTagIdGet**](TagsApi.md#readtagv1tagstagidget) | **GET** /v1/tags/{tag_id} | Read Tag
[**readTagsV1TagsGet**](TagsApi.md#readtagsv1tagsget) | **GET** /v1/tags | Read Tags
[**updateTagGroupV1TagsGroupsGroupIdPatch**](TagsApi.md#updatetaggroupv1tagsgroupsgroupidpatch) | **PATCH** /v1/tags/groups/{group_id} | Update Tag Group
[**updateTagV1TagsTagIdPatch**](TagsApi.md#updatetagv1tagstagidpatch) | **PATCH** /v1/tags/{tag_id} | Update Tag


# **createTagGroupV1TagsGroupsPost**
> TagGroupRead createTagGroupV1TagsGroupsPost(tagGroupCreate)

Create Tag Group

태그 그룹 생성

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final TagGroupCreate tagGroupCreate = ; // TagGroupCreate | 

try {
    final response = api.createTagGroupV1TagsGroupsPost(tagGroupCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->createTagGroupV1TagsGroupsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagGroupCreate** | [**TagGroupCreate**](TagGroupCreate.md)|  | 

### Return type

[**TagGroupRead**](TagGroupRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createTagV1TagsPost**
> TagRead createTagV1TagsPost(tagCreate)

Create Tag

태그 생성

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final TagCreate tagCreate = ; // TagCreate | 

try {
    final response = api.createTagV1TagsPost(tagCreate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->createTagV1TagsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagCreate** | [**TagCreate**](TagCreate.md)|  | 

### Return type

[**TagRead**](TagRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteTagGroupV1TagsGroupsGroupIdDelete**
> JsonObject deleteTagGroupV1TagsGroupsGroupIdDelete(groupId)

Delete Tag Group

태그 그룹 삭제 (CASCADE로 태그도 삭제)

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final String groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteTagGroupV1TagsGroupsGroupIdDelete(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->deleteTagGroupV1TagsGroupsGroupIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteTagV1TagsTagIdDelete**
> JsonObject deleteTagV1TagsTagIdDelete(tagId)

Delete Tag

태그 삭제

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final String tagId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.deleteTagV1TagsTagIdDelete(tagId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->deleteTagV1TagsTagIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagId** | **String**|  | 

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readTagGroupV1TagsGroupsGroupIdGet**
> TagGroupReadWithTags readTagGroupV1TagsGroupsGroupIdGet(groupId)

Read Tag Group

태그 그룹 조회 (태그 포함)

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final String groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.readTagGroupV1TagsGroupsGroupIdGet(groupId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->readTagGroupV1TagsGroupsGroupIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 

### Return type

[**TagGroupReadWithTags**](TagGroupReadWithTags.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readTagGroupsV1TagsGroupsGet**
> BuiltList<TagGroupReadWithTags> readTagGroupsV1TagsGroupsGet()

Read Tag Groups

모든 태그 그룹 조회 (태그 포함)

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();

try {
    final response = api.readTagGroupsV1TagsGroupsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->readTagGroupsV1TagsGroupsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;TagGroupReadWithTags&gt;**](TagGroupReadWithTags.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readTagV1TagsTagIdGet**
> TagRead readTagV1TagsTagIdGet(tagId)

Read Tag

태그 조회

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final String tagId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.readTagV1TagsTagIdGet(tagId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->readTagV1TagsTagIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagId** | **String**|  | 

### Return type

[**TagRead**](TagRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **readTagsV1TagsGet**
> BuiltList<TagRead> readTagsV1TagsGet()

Read Tags

모든 태그 조회

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();

try {
    final response = api.readTagsV1TagsGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->readTagsV1TagsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;TagRead&gt;**](TagRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTagGroupV1TagsGroupsGroupIdPatch**
> TagGroupRead updateTagGroupV1TagsGroupsGroupIdPatch(groupId, tagGroupUpdate)

Update Tag Group

태그 그룹 업데이트

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final String groupId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final TagGroupUpdate tagGroupUpdate = ; // TagGroupUpdate | 

try {
    final response = api.updateTagGroupV1TagsGroupsGroupIdPatch(groupId, tagGroupUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->updateTagGroupV1TagsGroupsGroupIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupId** | **String**|  | 
 **tagGroupUpdate** | [**TagGroupUpdate**](TagGroupUpdate.md)|  | 

### Return type

[**TagGroupRead**](TagGroupRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTagV1TagsTagIdPatch**
> TagRead updateTagV1TagsTagIdPatch(tagId, tagUpdate)

Update Tag

태그 업데이트

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getTagsApi();
final String tagId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final TagUpdate tagUpdate = ; // TagUpdate | 

try {
    final response = api.updateTagV1TagsTagIdPatch(tagId, tagUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TagsApi->updateTagV1TagsTagIdPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tagId** | **String**|  | 
 **tagUpdate** | [**TagUpdate**](TagUpdate.md)|  | 

### Return type

[**TagRead**](TagRead.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

