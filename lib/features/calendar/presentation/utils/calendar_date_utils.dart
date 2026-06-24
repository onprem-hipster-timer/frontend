import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';

// ============================================================
// 캘린더 날짜 계산 유틸리티
// ============================================================

/// SfCalendar 월간 뷰가 한 화면에 그리는 주 수.
///
/// `MonthViewSettings.numberOfWeeksInView`의 기본값(6주)과 일치시켜,
/// 화면에 보이는 다음 달 앞부분 셀까지 조회 범위에 포함되도록 한다.
const int monthWeeksInView = 6;

/// 주 시작 요일([firstDayOfWeek], 1 = 월요일 … 7 = 일요일) 기준으로
/// [date]가 속한 주의 시작일(로컬 자정)을 반환한다.
DateTime startOfWeek(DateTime date, int firstDayOfWeek) {
  final delta = (date.weekday - firstDayOfWeek) % DateTime.daysPerWeek;
  final start = date.subtract(Duration(days: delta));
  return DateTime(start.year, start.month, start.day);
}

/// 뷰 타입별로 캘린더가 조회·표시해야 할 `[start, end)` 날짜 범위를 계산한다.
/// (end는 exclusive)
///
/// 월간/아젠다 뷰는 SfCalendar가 항상 [monthWeeksInView]주를 그리므로,
/// 그 달의 첫 주 시작일부터 6주 전체를 덮어 화면에 보이는 다음 달 앞부분
/// 셀의 일정·휴일도 함께 조회되도록 한다.
(DateTime, DateTime) visibleDateRange({
  required CalendarViewType viewType,
  required int firstDayOfWeek,
  required DateTime displayDate,
}) {
  switch (viewType) {
    case CalendarViewType.day:
      final startDate = DateTime(
        displayDate.year,
        displayDate.month,
        displayDate.day,
      );
      return (startDate, startDate.add(const Duration(days: 1)));
    case CalendarViewType.week:
      final startDate = startOfWeek(displayDate, firstDayOfWeek);
      return (
        startDate,
        startDate.add(const Duration(days: DateTime.daysPerWeek)),
      );
    case CalendarViewType.month:
    case CalendarViewType.agenda:
      final firstOfMonth = DateTime(displayDate.year, displayDate.month, 1);
      final startDate = startOfWeek(firstOfMonth, firstDayOfWeek);
      return (
        startDate,
        startDate.add(
          const Duration(days: DateTime.daysPerWeek * monthWeeksInView),
        ),
      );
    case CalendarViewType.year:
      return (
        DateTime(displayDate.year, 1, 1),
        DateTime(displayDate.year + 1, 1, 1),
      );
  }
}
