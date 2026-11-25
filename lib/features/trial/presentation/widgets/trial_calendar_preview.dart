import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/calendar.dart'
    show
        CalendarSettingsState,
        CalendarViewWidgetView,
        ScheduleCalendarDataSource;
import 'package:momeet/shared/api/rest/export.dart';

/// 체험하기 견본 일정이 든 두 주의 달력. 앱의 달력([CalendarViewWidgetView])을 앱처럼 월 보기로 그리되, 요일 줄
/// 아래에 시험([exam])과 약속([dinner])이 든 두 주만 둔다. 고른 날은 [today]다. 누르는 것은 아무것도 하지 않는다.
///
/// 테스트: test/features/trial/presentation/pages/trial_preview_page_test.dart
class TrialCalendarPreview extends StatelessWidget {
  const TrialCalendarPreview({
    super.key,
    required this.exam,
    required this.dinner,
    required this.today,
  });

  final ScheduleRead exam;
  final ScheduleRead dinner;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return CalendarViewWidgetView(
      settings: CalendarSettingsState(
        selectedDate: today,
        displayDate: _firstDay(),
        firstDayOfWeek: DateTime.sunday,
      ),
      schedules: AsyncData(ScheduleCalendarDataSource([exam, dinner])),
      holidays: const [],
      onRetry: () {},
      onDisplayDateChanged: (_) {},
      onMoreTap: (_) {},
      onDateTap: (_) {},
      onDragEnd: (_) {},
      onResizeEnd: (_) {},
      monthWeeks: 2,
    );
  }

  /// 두 주의 첫날(일요일). 달력은 둘째 주 첫날의 달을 이번 달로 그리므로, 그날이 시험의 달에 들게 고른다.
  /// 시험과 약속은 같은 달 안에서 사흘 떨어져 있어 두 주에 모두 든다
  DateTime _firstDay() {
    final examDay = exam.startTime.toLocal();
    final dinnerDay = dinner.startTime.toLocal();
    final later = examDay.isAfter(dinnerDay) ? examDay : dinnerDay;
    final earlier = identical(later, examDay) ? dinnerDay : examDay;
    final laterWeek = _sunday(later);
    return laterWeek.month == examDay.month
        ? DateTime(laterWeek.year, laterWeek.month, laterWeek.day - 7)
        : _sunday(earlier);
  }

  static DateTime _sunday(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day - day.weekday % DateTime.daysPerWeek,
  );
}
