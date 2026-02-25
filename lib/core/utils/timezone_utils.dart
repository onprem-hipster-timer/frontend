/// 기기 로컬 타임존 오프셋을 API용 문자열로 반환합니다.
///
/// 예: +09:00 (한국), -05:00 (미동부), +00:00 (UTC).
/// REST/WebSocket의 [timezone] 쿼리 파라미터에 사용합니다.
String deviceTimezoneOffsetString() {
  final offset = DateTime.now().timeZoneOffset;
  final totalMinutes = offset.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes.remainder(60).abs();
  final sign = totalMinutes >= 0 ? '+' : '-';
  return '$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}
