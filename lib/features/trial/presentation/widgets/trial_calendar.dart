import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/calendar.dart'
    show
        CalendarSettingsState,
        CalendarViewWidgetView,
        ScheduleCalendarDataSource,
        showScheduleListSheet;
import 'package:momeet/shared/api/rest/export.dart';

/// 체험하기 첫 단계의 달력. 앱의 달력([CalendarViewWidgetView])을 앱처럼 월 보기로, 시험([exam])의 달을 열어
/// [exam]과 [dinner]를 담는다. 고른 날은 앱처럼 [today]에서 시작해 누른 날로 바뀐다(그때 월 보기로 돌아온다).
///
/// 시험 날짜를 누르면 앱처럼 그날의 일정 목록 시트를 열고, 시트나 달력에서 시험을 누르면 [onOpenExam]을 부른다.
/// 다른 날짜와 일정, 끌기는 반응하지 않는다
class TrialCalendar extends StatefulWidget {
  const TrialCalendar({
    super.key,
    required this.exam,
    required this.dinner,
    required this.today,
    required this.onOpenExam,
  });

  final ScheduleRead exam;
  final ScheduleRead dinner;
  final DateTime today;
  final VoidCallback onOpenExam;

  @override
  State<TrialCalendar> createState() => _TrialCalendarState();
}

class _TrialCalendarState extends State<TrialCalendar> {
  late var _selected = widget.today;

  /// 보는 달. 넘기면 바뀐다
  late var _shown = DateTime(
    widget.exam.startTime.toLocal().year,
    widget.exam.startTime.toLocal().month,
  );

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final start = exam.startTime.toLocal();
    void openDay(DateTime date) {
      setState(() => _selected = date);
      if (!DateUtils.isSameDay(date, start)) return;
      showScheduleListSheet(context, date, [
        exam,
      ], onScheduleTap: (_) => widget.onOpenExam());
    }

    return CalendarViewWidgetView(
      settings: CalendarSettingsState(
        selectedDate: _selected,
        displayDate: _shown,
        firstDayOfWeek: DateTime.sunday,
      ),
      schedules: AsyncData(ScheduleCalendarDataSource([exam, widget.dinner])),
      holidays: const [],
      onRetry: () {},
      onDisplayDateChanged: (date) => _shown = date,
      onScheduleTap: (id) {
        if (id == exam.id) widget.onOpenExam();
      },
      onMoreTap: openDay,
      onDateTap: openDay,
      onDragEnd: (_) {},
      onResizeEnd: (_) {},
    );
  }
}
