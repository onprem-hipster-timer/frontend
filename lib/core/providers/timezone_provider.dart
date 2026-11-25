// Timezone Provider - 앱 전체 타임존 상태 관리
//
// timezone 패키지(IANA DB)를 사용하여 타임존을 관리하고
// SharedPreferences에 사용자 선택을 영속합니다.
// flutter_timezone 패키지로 디바이스 로컬 타임존을 자동 감지합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:momeet/core/providers/shared_preferences_provider.dart';

export 'package:momeet/core/utils/timezone_utils.dart'
    show getAllTimezones, getTimezoneDisplayName;

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
