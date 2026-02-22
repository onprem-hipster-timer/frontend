// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/holiday_item.dart';

part 'holidays_client.g.dart';

@RestApi()
abstract class HolidaysClient {
  factory HolidaysClient(Dio dio, {String? baseUrl}) = _HolidaysClient;

  /// Get Holidays.
  ///
  /// 공휴일 조회.
  ///
  /// - year만 지정: 해당 연도 조회.
  /// - start_year/end_year 지정: 범위 조회 (end_year 없으면 start_year로 대체).
  /// - 미지정: 현재 연도 조회.
  /// - auto_sync=False (기본값): DB에 있는 데이터만 반환.
  /// - auto_sync=True: 데이터가 없으면 자동으로 동기화 수행 후 결과 반환.
  /// - 422 에러: 해당 연도의 공휴일 데이터가 준비되지 않은 경우 (2028년 이후 등).
  ///
  /// [year] - 조회 연도 (YYYY).
  ///
  /// [startYear] - 시작 연도 (YYYY).
  ///
  /// [endYear] - 종료 연도 (YYYY).
  ///
  /// [autoSync] - 데이터가 없을 경우 자동으로 동기화 실행.
  @GET('/v1/holidays')
  Future<List<HolidayItem>> getHolidaysV1HolidaysGet({
    @Query('auto_sync') bool? autoSync = false,
    @Query('year') int? year,
    @Query('start_year') int? startYear,
    @Query('end_year') int? endYear,
    @DioOptions() RequestOptions? options,
  });
}
