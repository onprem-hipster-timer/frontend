import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:momeet/features/calendar/presentation/widgets/holiday_detail_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// 달력 화면(CalendarViewWidget)에서 칸을 누르거나 일정을 끌었을 때 하는 일

/// [date]를 고른다. 그날 일정이 있으면 일정 목록을, 공휴일이면 공휴일 안내를, 아니면 새 일정 폼을 연다
///
/// 공휴일을 불러오는 중이거나 못 불러와도 일정 목록·새 일정 폼은 연다.
void openCalendarDate(BuildContext context, WidgetRef ref, DateTime date) {
  ref.read(calendarSettingsProvider.notifier).setSelectedDate(date);
  // 여러 날에 걸친 일정도 그날 일정으로 센다
  final hasAppointments =
      ref
          .read(scheduleOnlyDataSourceProvider)
          .value
          ?.getAppointmentsForDate(date)
          .isNotEmpty ??
      false;
  final holiday = ref
      .read(currentHolidaysProvider)
      .whenOrNull(data: (holidays) => holidayOn(holidays, date));
  if (!context.mounted) return;
  if (hasAppointments) {
    openSchedulesOnDay(context, ref, date);
  } else if (holiday != null) {
    showHolidayDetailSheet(context, holiday);
  } else {
    showScheduleFormSheet(context, initialDate: date);
  }
}

/// [date]에 걸친 일정 목록 시트를 연다. 그날 일정이 없으면 열지 않는다
void openSchedulesOnDay(BuildContext context, WidgetRef ref, DateTime date) {
  final schedules = ref.read(filteredSchedulesProvider).value ?? const [];
  final daySchedules = schedules
      .where(
        (s) =>
            fmt.isIncludeDay(s.startTime.toLocal(), s.endTime.toLocal(), date),
      )
      .toList();
  if (daySchedules.isEmpty || !context.mounted) return;
  showScheduleListSheet(context, date, daySchedules);
}

/// 끌어 놓은 일정을 길이는 그대로 두고 놓은 시각으로 옮긴다. 공휴일 등 일정이 아닌 것은 무시한다
void moveDraggedSchedule(WidgetRef ref, AppointmentDragEndDetails details) {
  final appointment = details.appointment as Appointment?;
  final id = appointment?.id as String?;
  final droppingTime = details.droppingTime;
  if (appointment == null || id == null || droppingTime == null) return;
  final duration = appointment.endTime.difference(appointment.startTime);
  updateScheduleMutation.run(
    ref,
    (tsx) => tsx
        .get(scheduleMutationsProvider.notifier)
        .moveSchedule(
          id,
          newStartTime: droppingTime,
          newEndTime: droppingTime.add(duration),
        ),
  );
}

/// 길이를 바꾼 일정을 새 시작·종료로 보낸다. 일정이 아닌 것은 무시한다
void resizeSchedule(WidgetRef ref, AppointmentResizeEndDetails details) {
  final appointment = details.appointment as Appointment?;
  final id = appointment?.id as String?;
  if (id == null) return;
  updateScheduleMutation.run(
    ref,
    (tsx) => tsx
        .get(scheduleMutationsProvider.notifier)
        .resizeSchedule(
          id,
          newStartTime: details.startTime,
          newEndTime: details.endTime!,
        ),
  );
}
