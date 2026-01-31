# openapi_client.api.HolidaysApi

## Load the API package
```dart
import 'package:openapi_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getHolidaysV1HolidaysGet**](HolidaysApi.md#getholidaysv1holidaysget) | **GET** /v1/holidays | Get Holidays


# **getHolidaysV1HolidaysGet**
> BuiltList<HolidayItem> getHolidaysV1HolidaysGet(year, startYear, endYear, autoSync)

Get Holidays

공휴일 조회  - year만 지정: 해당 연도 조회 - start_year/end_year 지정: 범위 조회 (end_year 없으면 start_year로 대체) - 미지정: 현재 연도 조회 - auto_sync=False (기본값): DB에 있는 데이터만 반환 - auto_sync=True: 데이터가 없으면 자동으로 동기화 수행 후 결과 반환 - 422 에러: 해당 연도의 공휴일 데이터가 준비되지 않은 경우 (2028년 이후 등)

### Example
```dart
import 'package:openapi_client/api.dart';

final api = OpenapiClient().getHolidaysApi();
final int year = 56; // int | 조회 연도 (YYYY)
final int startYear = 56; // int | 시작 연도 (YYYY)
final int endYear = 56; // int | 종료 연도 (YYYY)
final bool autoSync = true; // bool | 데이터가 없을 경우 자동으로 동기화 실행

try {
    final response = api.getHolidaysV1HolidaysGet(year, startYear, endYear, autoSync);
    print(response);
} catch on DioException (e) {
    print('Exception when calling HolidaysApi->getHolidaysV1HolidaysGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **year** | **int**| 조회 연도 (YYYY) | [optional] 
 **startYear** | **int**| 시작 연도 (YYYY) | [optional] 
 **endYear** | **int**| 종료 연도 (YYYY) | [optional] 
 **autoSync** | **bool**| 데이터가 없을 경우 자동으로 동기화 실행 | [optional] [default to false]

### Return type

[**BuiltList&lt;HolidayItem&gt;**](HolidayItem.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

