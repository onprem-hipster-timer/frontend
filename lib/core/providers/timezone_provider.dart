// Timezone Provider - 앱 전체 타임존 상태 관리
//
// timezone 패키지(IANA DB)를 사용하여 타임존을 관리하고
// SharedPreferences에 사용자 선택을 영속합니다.
// flutter_timezone 패키지로 디바이스 로컬 타임존을 자동 감지합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:momeet/core/providers/shared_preferences_provider.dart';

// ============================================================
// Constants
// ============================================================

/// SharedPreferences 키
const String _timezoneKey = 'user_timezone';

/// 기본 타임존 (디바이스 감지 실패 시 최종 fallback)
const String defaultTimezone = 'Asia/Seoul';

// ============================================================
// Timezone Provider
// ============================================================

/// 타임존 상태 관리 Notifier (IANA timezone ID를 상태로 관리)
///
/// 초기화 우선순위:
/// 1. SharedPreferences에 저장된 사용자 선택
/// 2. 디바이스 로컬 타임존 자동 감지 (flutter_timezone)
/// 3. [defaultTimezone] fallback
class TimezoneNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_timezoneKey);
    // 저장된 값이 IANA DB에 존재하는지 확인
    if (saved != null && tz.timeZoneDatabase.locations.containsKey(saved)) {
      return saved;
    }

    // 디바이스 로컬 타임존 자동 감지
    try {
      final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
      final deviceTz = deviceTzInfo.identifier;
      if (tz.timeZoneDatabase.locations.containsKey(deviceTz)) {
        return deviceTz;
      }
    } catch (_) {
      // 감지 실패 시 fallback
    }

    return defaultTimezone;
  }

  /// 타임존 업데이트 (상태 + 영구 저장)
  Future<void> updateTimezone(String newTimezone) async {
    if (!tz.timeZoneDatabase.locations.containsKey(newTimezone)) {
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_timezoneKey, newTimezone);
    state = AsyncData(newTimezone);
  }

  /// 타임존 리셋 (기본값으로 복원)
  Future<void> resetTimezone() async {
    await updateTimezone(defaultTimezone);
  }
}

/// 타임존 상태 Provider
final timezoneProvider = AsyncNotifierProvider<TimezoneNotifier, String>(
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

/// IANA 타임존 목록을 반환합니다 (UTC offset → 이름 순 정렬).
///
/// offset을 사전에 한 번만 계산하여 정렬 중 TZDateTime 재생성을 방지합니다.
/// DST 전환 시점에도 정렬 일관성을 보장합니다.
List<String> getAllTimezones() {
  final locations = tz.timeZoneDatabase.locations.keys.toList();

  final offsets = <String, Duration>{
    for (final id in locations)
      id: tz.TZDateTime.now(tz.getLocation(id)).timeZoneOffset,
  };

  locations.sort((a, b) {
    final offsetA = offsets[a]!;
    final offsetB = offsets[b]!;
    final cmp = offsetA.compareTo(offsetB);
    if (cmp != 0) return cmp;
    return a.compareTo(b);
  });
  return locations;
}
