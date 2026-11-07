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
