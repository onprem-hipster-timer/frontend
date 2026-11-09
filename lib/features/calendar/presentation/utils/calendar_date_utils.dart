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

/// [viewType]으로 볼 때 [date]가 든 기간의 첫날(로컬 자정).
/// 월·아젠다는 그달 1일, 주는 주 시작일, 일은 그날, 연은 1월 1일.
DateTime periodStart(
  CalendarViewType viewType,
  DateTime date,
  int firstDayOfWeek,
) => switch (viewType) {
  CalendarViewType.day => DateTime(date.year, date.month, date.day),
  CalendarViewType.week => startOfWeek(date, firstDayOfWeek),
  CalendarViewType.month ||
  CalendarViewType.agenda => DateTime(date.year, date.month, 1),
  CalendarViewType.year => DateTime(date.year, 1, 1),
};

/// [start]에서 시작하는 기간을 [step]만큼(음수면 이전) 옮긴 기간의 첫날.
DateTime shiftPeriod(CalendarViewType viewType, DateTime start, int step) =>
    switch (viewType) {
      CalendarViewType.day => DateTime(
        start.year,
        start.month,
        start.day + step,
      ),
      CalendarViewType.week => DateTime(
        start.year,
        start.month,
        start.day + DateTime.daysPerWeek * step,
      ),
      CalendarViewType.month ||
      CalendarViewType.agenda => DateTime(start.year, start.month + step, 1),
      CalendarViewType.year => DateTime(start.year + step, 1, 1),
    };

/// [start]에서 시작하는 기간에 [date]가 드는지.
bool periodContains(
  CalendarViewType viewType,
  DateTime start,
  DateTime date,
  int firstDayOfWeek,
) => periodStart(viewType, date, firstDayOfWeek) == start;

/// 월 보기 칸 하나에 읽을 수 있게 들어가는 일정 수(1~6).
///
/// 달력은 칸에서 날짜 숫자 자리를 뺀 높이를 일정 수로 똑같이 나눈다. 날짜 자리는 글자 배율에
/// 비례하고(1.0에서 약 42), 11pt 일정 한 줄은 18 × 배율은 돼야 읽힌다. 이 값은 기기 크기
/// 14종 × 글자 배율 1.0·1.3에서 월 칸을 그려 잰 것이다.
int autoMonthEventsPerDay({
  required double cellHeight,
  required double textScale,
}) {
  final dateHeader = 20 + 22 * textScale;
  final minRow = 18 * textScale;
  return ((cellHeight - dateHeader) / minRow).floor().clamp(1, 6);
}
