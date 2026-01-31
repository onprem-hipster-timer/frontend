# momeet_api.api.HealthApi

## Load the API package
```dart
import 'package:momeet_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthCheckHealthGet**](HealthApi.md#healthcheckhealthget) | **GET** /health | Health Check


# **healthCheckHealthGet**
> JsonObject healthCheckHealthGet()

Health Check

애플리케이션 상태 확인  로드밸런서, Kubernetes, ECS 등에서 사용하는 health check 엔드포인트. 인증 없이 접근 가능합니다.

### Example
```dart
import 'package:momeet_api/api.dart';

final api = MomeetApi().getHealthApi();

try {
    final response = api.healthCheckHealthGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling HealthApi->healthCheckHealthGet: $e\n');
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

