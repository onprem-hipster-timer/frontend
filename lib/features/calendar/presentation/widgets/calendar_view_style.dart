import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// 달력 화면(CalendarViewWidget)이 SfCalendar에 넘기는 보기별 스타일 설정

ViewHeaderStyle calendarViewHeaderStyle(ColorScheme colorScheme) =>
    ViewHeaderStyle(
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      ),
      dayTextStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      dateTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

/// [eventsPerDay]는 월 칸 하나에 보일 일정 수
MonthViewSettings calendarMonthViewSettings(
  ColorScheme colorScheme,
  int eventsPerDay,
) => MonthViewSettings(
  showAgenda: false,
  appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
  appointmentDisplayCount: eventsPerDay,
  monthCellStyle: MonthCellStyle(
    textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 14),
    trailingDatesTextStyle: TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.4),
      fontSize: 14,
    ),
    leadingDatesTextStyle: TextStyle(
      color: colorScheme.onSurface.withValues(alpha: 0.4),
      fontSize: 14,
    ),
    backgroundColor: colorScheme.surface,
    todayBackgroundColor: colorScheme.primary.withValues(alpha: 0.1),
  ),
  showTrailingAndLeadingDates: true,
);

TimeSlotViewSettings calendarTimeSlotViewSettings(
  ColorScheme colorScheme, {
  required bool use24HourFormat,
}) => TimeSlotViewSettings(
  startHour: 0,
  endHour: 24,
  timeIntervalHeight: 60,
  timeFormat: use24HourFormat ? 'HH:mm' : 'h:mm a',
  timeTextStyle: TextStyle(
    color: colorScheme.onSurface.withValues(alpha: 0.6),
    fontSize: 11,
  ),
  timeRulerSize: 60,
  dayFormat: 'EEE',
  dateFormat: 'd',
);

ScheduleViewSettings calendarScheduleViewSettings(
  ColorScheme colorScheme,
) => ScheduleViewSettings(
  appointmentTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 13),
  dayHeaderSettings: DayHeaderSettings(
    dayFormat: 'EEEE',
    width: 70,
    dayTextStyle: TextStyle(
      color: colorScheme.primary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    dateTextStyle: TextStyle(
      color: colorScheme.primary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  weekHeaderSettings: WeekHeaderSettings(
    startDateFormat: 'MMM d',
    endDateFormat: 'MMM d, yyyy',
    textAlign: TextAlign.center,
    backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
  ),
  monthHeaderSettings: MonthHeaderSettings(
    monthFormat: 'MMMM yyyy',
    height: 50,
    backgroundColor: colorScheme.surfaceContainerHighest,
    textAlign: TextAlign.center,
    monthTextStyle: TextStyle(
      color: colorScheme.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
);

BoxDecoration calendarSelectionDecoration(ColorScheme colorScheme) =>
    BoxDecoration(
      color: colorScheme.primary.withValues(alpha: 0.1),
      border: Border.all(color: colorScheme.primary, width: 1.5),
      borderRadius: AppRadius.smAll,
    );

/// 일·주 보기에서 공휴일 하루를 [color]로 옅게 칠하고 이름을 쓰는 구역
List<TimeRegion> calendarHolidayRegions(
  List<HolidayItem> holidays,
  Color color,
) => [
  for (final holiday in holidays)
    if (holiday.isHoliday)
      if (parseHolidayDate(holiday.locdate) case final date?)
        TimeRegion(
          startTime: date,
          endTime: date.add(const Duration(days: 1)),
          text: holiday.dateName,
          color: color.withValues(alpha: 0.1),
          enablePointerInteraction: false,
          textStyle: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
];
