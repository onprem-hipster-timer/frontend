// Timezone Provider - 앱 전체 타임존 상태 관리
//
// timezone 패키지(IANA DB)를 사용하여 타임존을 관리하고
// SharedPreferences에 사용자 선택을 영속합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:momeet/core/providers/shared_preferences_provider.dart';

// ============================================================
// Constants
// ============================================================

/// SharedPreferences 키
const String _timezoneKey = 'user_timezone';

/// 기본 타임존
const String defaultTimezone = 'Asia/Seoul';

// ============================================================
// Timezone Provider
// ============================================================

/// 타임존 상태 관리 Notifier (IANA timezone ID를 상태로 관리)
class TimezoneNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_timezoneKey);
    // 저장된 값이 IANA DB에 존재하는지 확인
    if (saved != null && tz.timeZoneDatabase.locations.containsKey(saved)) {
      return saved;
    }
    return defaultTimezone;
  }

  /// 타임존 업데이트 (상태 + 영구 저장)
  Future<void> updateTimezone(String newTimezone) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_timezoneKey, newTimezone);
    state = newTimezone;
  }

  /// 타임존 리셋 (기본값으로 복원)
  Future<void> resetTimezone() async {
    await updateTimezone(defaultTimezone);
  }
}

/// 타임존 상태 Provider
final timezoneProvider = NotifierProvider<TimezoneNotifier, String>(
  TimezoneNotifier.new,
);

// ============================================================
// Helper Functions
// ============================================================

/// IANA 타임존 ID에서 도시 이름을 추출합니다.
///
/// 예: 'Asia/Seoul' → 'Seoul', 'America/New_York' → 'New York'
String _extractCity(String timezoneId) {
  final parts = timezoneId.split('/');
  final city = parts.length > 1 ? parts.last : timezoneId;
  return city.replaceAll('_', ' ');
}

/// 현재 시각 기준 UTC offset 문자열을 반환합니다.
///
/// 예: '+09:00', '-05:00', '+05:30'
String _formatOffset(tz.Location location) {
  final now = tz.TZDateTime.now(location);
  final offset = now.timeZoneOffset;
  final totalMinutes = offset.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes.remainder(60).abs();
  final sign = totalMinutes >= 0 ? '+' : '-';
  return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

/// 타임존을 사용자 친화적인 이름으로 변환합니다.
///
/// 예: 'Asia/Seoul' → 'Seoul (UTC+09:00)'
String getTimezoneDisplayName(String timezoneId) {
  final locations = tz.timeZoneDatabase.locations;
  if (!locations.containsKey(timezoneId)) return timezoneId;

  final location = locations[timezoneId]!;
  final city = _extractCity(timezoneId);
  final offset = _formatOffset(location);
  return '$city (UTC$offset)';
}

/// IANA 타임존 목록을 반환합니다 (도시 이름 기준 정렬).
List<String> getAllTimezones() {
  final locations = tz.timeZoneDatabase.locations.keys.toList();
  locations.sort((a, b) {
    final offsetA = tz.TZDateTime.now(tz.getLocation(a)).timeZoneOffset;
    final offsetB = tz.TZDateTime.now(tz.getLocation(b)).timeZoneOffset;
    final cmp = offsetA.compareTo(offsetB);
    if (cmp != 0) return cmp;
    return a.compareTo(b);
  });
  return locations;
}
