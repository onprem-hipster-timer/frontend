import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/export.dart';

part 'holiday_provider.g.dart';

// ============================================================
// 휴일 데이터 Provider
// ============================================================

/// 연도별 휴일 조회 Provider
///
/// Family Provider를 사용하여 연도별로 휴일을 캐시합니다.
/// 휴일 데이터는 변동이 적으므로 keepAlive를 활성화합니다.
@riverpod
Future<List<HolidayItem>> holidays(
  Ref ref,
  int year, {
  bool autoSync = true,
}) async {
  // 캐시 유지 (휴일 데이터는 변동이 적음)
  ref.keepAlive();

  final api = ref.watch(holidaysApiProvider);

  try {
    final response = await api.getHolidaysV1HolidaysGet(
      year: year,
      autoSync: autoSync,
    );

    return response;
  } catch (error) {
    // 에러 발생 시 빈 리스트 반환 (캘린더가 중단되지 않도록)
    debugPrint('휴일 조회 실패: $error');
    return [];
  }
}

/// 휴일 날짜 문자열을 DateTime으로 파싱
///
/// locdate 형식: "20241225" -> DateTime(2024, 12, 25)
DateTime? parseHolidayDate(String locdate) {
  if (locdate.length != 8) return null;

  try {
    final year = int.parse(locdate.substring(0, 4));
    final month = int.parse(locdate.substring(4, 6));
    final day = int.parse(locdate.substring(6, 8));

    return DateTime(year, month, day);
  } catch (e) {
    debugPrint('휴일 날짜 파싱 실패: $locdate');
    return null;
  }
}
