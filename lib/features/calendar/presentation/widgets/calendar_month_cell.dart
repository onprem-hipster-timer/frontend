import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// 월 보기의 날짜 칸. 모양은 [CalendarMonthCellView]
///
/// 공휴일을 불러오는 중이거나 못 불러오면 날짜만 보인다.
class CalendarMonthCell extends ConsumerWidget {
  const CalendarMonthCell({super.key, required this.details});

  final MonthCellDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = details.date;
    final isToday = fmt.isSameDay(date, DateTime.now());
    final visible = details.visibleDates;
    final isCurrentMonth = date.month == visible[visible.length ~/ 2].month;
    final highlightWeekends = ref.watch(
      calendarSettingsProvider.select((s) => s.highlightWeekends),
    );
    final holiday = ref
        .watch(currentHolidaysProvider)
        .whenOrNull(data: (holidays) => holidayOn(holidays, date));
    return CalendarMonthCellView(
      date: date,
      isToday: isToday,
      isCurrentMonth: isCurrentMonth,
      highlightWeekends: highlightWeekends,
      holidayName: holiday?.dateName,
    );
  }
}
