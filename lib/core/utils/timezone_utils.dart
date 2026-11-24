import 'package:timezone/timezone.dart' as tz;

/// [Duration] 오프셋을 `"+HH:mm"` / `"-HH:mm"` 형식 문자열로 변환합니다.
///
/// 예: `Duration(hours: 9)` → `'+09:00'`, `Duration(hours: -5)` → `'-05:00'`,
///     `Duration(hours: 5, minutes: 30)` → `'+05:30'`.
String formatUtcOffset(Duration offset) {
  final totalMinutes = offset.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes.remainder(60).abs();
  final sign = totalMinutes >= 0 ? '+' : '-';
  return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

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
  return formatUtcOffset(tz.TZDateTime.now(location).timeZoneOffset);
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
