import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// 월 보기의 날짜 칸. 날짜 숫자와, 공휴일이면 그 이름을 보인다.
///
/// 공휴일을 불러오는 중이거나 못 불러오면 날짜만 보인다.
class CalendarMonthCell extends ConsumerWidget {
  const CalendarMonthCell({super.key, required this.details});

  final MonthCellDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = details.date;
    final isToday = fmt.isSameDay(date, DateTime.now());
    final visible = details.visibleDates;
    final isCurrentMonth = date.month == visible[visible.length ~/ 2].month;
    final highlightWeekends = ref.watch(
      calendarSettingsProvider.select((s) => s.highlightWeekends),
    );
    final holiday = ref
        .watch(currentHolidaysProvider)
        .whenOrNull(
          data: (holidays) => holidays.where((h) {
            final holidayDate = parseHolidayDate(h.locdate);
            return h.isHoliday &&
                holidayDate != null &&
                fmt.isSameDay(holidayDate, date);
          }).firstOrNull,
        );
    final dateStyle = _dateTextStyle(
      date: date,
      isHoliday: holiday != null,
      isCurrentMonth: isCurrentMonth,
      highlightWeekends: highlightWeekends,
      colorScheme: colorScheme,
      colors: AppColors.of(context),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 0.5,
        ),
        color: isToday
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surface,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: _DayNumber(
              day: date.day,
              isToday: isToday,
              color: dateStyle.color,
              weight: dateStyle.weight,
            ),
          ),
          if (holiday != null)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 60),
                child: Text(
                  holiday.dateName,
                  style: TextStyle(
                    color: AppColors.of(context).holiday,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 날짜 숫자. 오늘이면 강조 색 동그라미 안에 둔다.
class _DayNumber extends StatelessWidget {
  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.color,
    required this.weight,
  });

  final int day;
  final bool isToday;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return isToday
        ? CircleAvatar(
            radius: 12,
            backgroundColor: colorScheme.primary,
            child: Text(
              '$day',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : Text(
            '$day',
            style: TextStyle(color: color, fontSize: 14, fontWeight: weight),
          );
  }
}

/// 날짜 숫자 스타일.
///
/// 한국 달력 관례에 따라 공휴일·일요일은 빨강, 토요일은 파랑으로 표시하고,
/// 나머지는 현재 달 여부에 따라 기본/흐림 색을 쓴다. 주말 강조는
/// [highlightWeekends] 설정으로 끌 수 있으나, 공휴일은 항상 강조한다.
({Color color, FontWeight weight}) _dateTextStyle({
  required DateTime date,
  required bool isHoliday,
  required bool isCurrentMonth,
  required bool highlightWeekends,
  required ColorScheme colorScheme,
  required AppColors colors,
}) {
  final isSunday = date.weekday == DateTime.sunday;
  final isSaturday = date.weekday == DateTime.saturday;

  if (isHoliday || (highlightWeekends && isSunday)) {
    return (color: colors.holiday, weight: FontWeight.w600);
  }
  if (highlightWeekends && isSaturday) {
    return (color: colors.saturday, weight: FontWeight.w600);
  }
  final base = isCurrentMonth
      ? colorScheme.onSurface
      : colorScheme.onSurface.withValues(alpha: 0.4);
  return (color: base, weight: FontWeight.normal);
}
