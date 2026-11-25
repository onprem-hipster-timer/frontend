import 'package:flutter/foundation.dart';
import 'package:momeet/shared/api/rest/export.dart';

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

/// [holidays] 중 [date]에 쉬는 날(isHoliday). 없으면 null
HolidayItem? holidayOn(Iterable<HolidayItem> holidays, DateTime date) {
  return holidays.where((h) {
    final holidayDate = parseHolidayDate(h.locdate);
    return h.isHoliday &&
        holidayDate != null &&
        holidayDate.year == date.year &&
        holidayDate.month == date.month &&
        holidayDate.day == date.day;
  }).firstOrNull;
}
