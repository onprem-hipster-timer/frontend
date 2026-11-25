import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

export 'package:momeet/features/calendar/domain/holidays.dart';

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
