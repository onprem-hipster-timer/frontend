import 'package:momeet/shared/api/rest/export.dart';

// ============================================================
// Timer History Sorting (순수 함수 — 테스트 용이)
// ============================================================

/// 타이머 히스토리를 정렬합니다.
///
/// 활성(RUNNING/PAUSED)이 상단, 완료(COMPLETED 등)가 하단 — 각 그룹 내 최신순.
List<TimerRead> sortTimerHistory(List<TimerRead> timers) {
  final sorted = List<TimerRead>.from(timers);
  sorted.sort((a, b) {
    final aActive =
        a.status == TimerStatus.running || a.status == TimerStatus.paused;
    final bActive =
        b.status == TimerStatus.running || b.status == TimerStatus.paused;
    if (aActive != bActive) return aActive ? -1 : 1;

    final aStarted = a.startedAt ?? a.createdAt;
    final bStarted = b.startedAt ?? b.createdAt;
    return bStarted.compareTo(aStarted);
  });
  return sorted;
}

// ============================================================
// Utility Functions
// ============================================================

/// DateTime을 MM/DD 형식으로 변환 (날짜 표시용)
String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${local.month.toString().padLeft(2, '0')}/'
      '${local.day.toString().padLeft(2, '0')}';
}

/// 두 DateTime 객체가 같은 날인지 확인
bool isSameDay(DateTime a, DateTime b) {
  final localA = a.toLocal();
  final localB = b.toLocal();

  return localA.year == localB.year &&
      localA.month == localB.month &&
      localA.day == localB.day;
}
