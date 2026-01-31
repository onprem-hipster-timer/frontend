# openapi_client.api.GraphQLApi

## Load the API package
```dart
import 'package:openapi_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**handleHttpGetV1GraphqlGet**](GraphQLApi.md#handlehttpgetv1graphqlget) | **GET** /v1/graphql | Handle Http Get
[**handleHttpPostV1GraphqlPost**](GraphQLApi.md#handlehttppostv1graphqlpost) | **POST** /v1/graphql | Handle Http Post


# **handleHttpGetV1GraphqlGet**
> JsonObject handleHttpGetV1GraphqlGet()

Handle Http Get

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getGraphQLApi();

try {
    final response = api.handleHttpGetV1GraphqlGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling GraphQLApi->handleHttpGetV1GraphqlGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **handleHttpPostV1GraphqlPost**
> JsonObject handleHttpPostV1GraphqlPost()

Handle Http Post

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getGraphQLApi();

try {
    final response = api.handleHttpPostV1GraphqlPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling GraphQLApi->handleHttpPostV1GraphqlPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**JsonObject**](JsonObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

