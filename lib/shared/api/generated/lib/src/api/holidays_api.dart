//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:built_collection/built_collection.dart';
import 'package:openapi_client/src/api_util.dart';
import 'package:openapi_client/src/model/holiday_item.dart';

class HolidaysApi {

  final Dio _dio;

  final Serializers _serializers;

  const HolidaysApi(this._dio, this._serializers);

  /// Get Holidays
  /// 공휴일 조회  - year만 지정: 해당 연도 조회 - start_year/end_year 지정: 범위 조회 (end_year 없으면 start_year로 대체) - 미지정: 현재 연도 조회 - auto_sync&#x3D;False (기본값): DB에 있는 데이터만 반환 - auto_sync&#x3D;True: 데이터가 없으면 자동으로 동기화 수행 후 결과 반환 - 422 에러: 해당 연도의 공휴일 데이터가 준비되지 않은 경우 (2028년 이후 등)
  ///
  /// Parameters:
  /// * [year] - 조회 연도 (YYYY)
  /// * [startYear] - 시작 연도 (YYYY)
  /// * [endYear] - 종료 연도 (YYYY)
  /// * [autoSync] - 데이터가 없을 경우 자동으로 동기화 실행
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [BuiltList<HolidayItem>] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<BuiltList<HolidayItem>>> getHolidaysV1HolidaysGet({ 
    int? year,
    int? startYear,
    int? endYear,
    bool? autoSync = false,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/holidays';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _queryParameters = <String, dynamic>{
      r'year': encodeQueryParameter(_serializers, year, const FullType(int)),
      r'start_year': encodeQueryParameter(_serializers, startYear, const FullType(int)),
      r'end_year': encodeQueryParameter(_serializers, endYear, const FullType(int)),
      if (autoSync != null) r'auto_sync': encodeQueryParameter(_serializers, autoSync, const FullType(bool)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    BuiltList<HolidayItem>? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(BuiltList, [FullType(HolidayItem)]),
      ) as BuiltList<HolidayItem>;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<BuiltList<HolidayItem>>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

}
