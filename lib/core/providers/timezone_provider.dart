// Timezone Provider - 앱 전체 타임존 상태 관리
//
// SharedPreferences를 사용하여 사용자가 선택한 타임존을 저장하고
// Riverpod으로 전역 상태를 관리합니다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// 타임존 상태 관리 Notifier
class TimezoneNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimezone = prefs.getString(_timezoneKey);

      if (savedTimezone != null) {
        return savedTimezone;
      }

      return defaultTimezone;
    } catch (e) {
      // SharedPreferences 로드 실패 시 기본값 유지
      return defaultTimezone;
    }
  }

  /// 타임존 업데이트 (상태 + 영구 저장)
  Future<void> updateTimezone(String newTimezone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timezoneKey, newTimezone);

      // 상태 업데이트
      state = AsyncData(newTimezone);
    } catch (e) {
      // 저장 실패 시 상태만 업데이트 (메모리에서는 변경됨)
      state = AsyncData(newTimezone);
    }
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

/// 타임존을 사용자 친화적인 이름으로 변환
String getTimezoneDisplayName(String timezone) {
  switch (timezone) {
    case 'Asia/Seoul':
      return '서울 (KST)';
    case 'Asia/Tokyo':
      return '도쿄 (JST)';
    case 'Asia/Shanghai':
      return '상하이 (CST)';
    case 'Asia/Hong_Kong':
      return '홍콩 (HKT)';
    case 'Asia/Singapore':
      return '싱가포르 (SGT)';
    case 'Europe/London':
      return '런던 (GMT/BST)';
    case 'Europe/Paris':
      return '파리 (CET/CEST)';
    case 'Europe/Berlin':
      return '베를린 (CET/CEST)';
    case 'America/New_York':
      return '뉴욕 (EST/EDT)';
    case 'America/Los_Angeles':
      return '로스앤젤레스 (PST/PDT)';
    case 'America/Chicago':
      return '시카고 (CST/CDT)';
    case 'America/Toronto':
      return '토론토 (EST/EDT)';
    case 'Australia/Sydney':
      return '시드니 (AEST/AEDT)';
    case 'Pacific/Auckland':
      return '오클랜드 (NZST/NZDT)';
    case 'UTC':
      return 'UTC (협정세계시)';
    default:
      return timezone;
  }
}

/// 지원되는 타임존 목록
const List<String> supportedTimezones = [
  'Asia/Seoul',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Asia/Hong_Kong',
  'Asia/Singapore',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'America/New_York',
  'America/Los_Angeles',
  'America/Chicago',
  'America/Toronto',
  'Australia/Sydney',
  'Pacific/Auckland',
  'UTC',
];
