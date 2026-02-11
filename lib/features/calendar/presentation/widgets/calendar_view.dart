import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/holiday_provider.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_appointment_builder.dart'
    as custom_builder;
import 'package:momeet/features/calendar/presentation/widgets/schedule_detail_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/holiday_detail_sheet.dart';

/// SfCalendar 위젯을 래핑한 캘린더 뷰
///
/// Riverpod Provider와 연결되어 상태 관리가 자동으로 됩니다.
/// onViewChanged, onTap 등의 콜백이 CalendarSettings와 연결됩니다.
class CalendarViewWidget extends ConsumerStatefulWidget {
  const CalendarViewWidget({
    super.key,
    this.onScheduleTap,
    this.onDateLongPress,
  });

  /// 일정을 탭했을 때 콜백
  final void Function(String scheduleId)? onScheduleTap;

  /// 날짜를 길게 눌렀을 때 콜백 (새 일정 생성용)
  final void Function(DateTime date)? onDateLongPress;

  @override
  ConsumerState<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends ConsumerState<CalendarViewWidget> {
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(calendarSettingsProvider);
    final dataSourceAsync = ref.watch(scheduleOnlyDataSourceProvider);

    // 컨트롤러와 Provider 상태 동기화
    _calendarController.view = settings.viewType.toSfCalendarView();
    _calendarController.selectedDate = settings.selectedDate;
    _calendarController.displayDate = settings.displayDate;

    return dataSourceAsync.when(
      data: (dataSource) => _buildCalendar(context, settings, dataSource),
      loading: () => _buildCalendar(
        context,
        settings,
        ScheduleOnlyDataSource([]),
        isLoading: true,
      ),
      error: (error, stack) => _buildErrorView(context, error),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    CalendarSettingsState settings,
    ScheduleOnlyDataSource dataSource, {
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        SfCalendar(
          controller: _calendarController,
          dataSource: dataSource,
          view: settings.viewType.toSfCalendarView(),
          firstDayOfWeek: settings.firstDayOfWeek,
          showNavigationArrow: false, // 커스텀 네비게이션 사용
          showDatePickerButton: false,
          showCurrentTimeIndicator: true,
          allowViewNavigation: true,
          allowDragAndDrop: true,
          allowAppointmentResize: true,

          // ============================================================
          // 휴일 표시 설정
          // ============================================================

          monthCellBuilder: _buildMonthCell, // 월간 뷰 휴일 표시
          specialRegions: _buildSpecialRegions(settings), // 일간/주간 뷰 휴일 표시

          // ============================================================
          // 콜백 설정
          // ============================================================

          onViewChanged: _onViewChanged,
          onTap: _onCalendarTap,
          onLongPress: _onCalendarLongPress,
          onDragEnd: _onDragEnd,
          onAppointmentResizeEnd: _onResizeEnd,

          // ============================================================
          // 스타일 설정
          // ============================================================

          backgroundColor: colorScheme.surface,
          cellBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
          todayHighlightColor: colorScheme.primary,

          headerStyle: const CalendarHeaderStyle(
            textAlign: TextAlign.center,
            backgroundColor: Colors.transparent,
            textStyle: TextStyle(
              fontSize: 0, // 헤더 숨김 (커스텀 헤더 사용)
            ),
          ),

          viewHeaderStyle: ViewHeaderStyle(
            backgroundColor: colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
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
          ),

          selectionDecoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: colorScheme.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),

          // ============================================================
          // 월간 뷰 설정
          // ============================================================

          monthViewSettings: MonthViewSettings(
            showAgenda: false,
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            appointmentDisplayCount: 3,
            monthCellStyle: MonthCellStyle(
              textStyle: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
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
          ),

          // ============================================================
          // 타임슬롯 설정 (Day/Week 뷰)
          // ============================================================

          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: 0,
            endHour: 24,
            timeIntervalHeight: 60,
            timeFormat: settings.use24HourFormat ? 'HH:mm' : 'h:mm a',
            timeTextStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 11,
            ),
            timeRulerSize: 60,
            dayFormat: 'EEE',
            dateFormat: 'd',
          ),

          // ============================================================
          // 스케줄 뷰 설정 (Agenda)
          // ============================================================

          scheduleViewSettings: ScheduleViewSettings(
            appointmentTextStyle: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 13,
            ),
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
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          ),

          // ============================================================
          // 일정 빌더
          // ============================================================

          appointmentBuilder: _appointmentBuilder,
        ),

        // 로딩 오버레이
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: colorScheme.surface.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  /// 일정 커스텀 빌더
  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final settings = ref.read(calendarSettingsProvider);

    switch (settings.viewType) {
      case CalendarViewType.month:
        return custom_builder.ScheduleAppointmentBuilder.buildMonthAppointment(
            context, details);
      case CalendarViewType.day:
      case CalendarViewType.week:
        return custom_builder.ScheduleAppointmentBuilder.buildTimeSlotAppointment(
            context, details);
      case CalendarViewType.agenda:
      case CalendarViewType.year:
        return custom_builder.ScheduleAppointmentBuilder.buildAgendaAppointment(
            context, details);
    }
  }

  /// 뷰 변경 콜백
  void _onViewChanged(ViewChangedDetails details) {
    // 표시 날짜 범위가 변경되었을 때
    if (details.visibleDates.isNotEmpty) {
      final middleIndex = details.visibleDates.length ~/ 2;
      final displayDate = details.visibleDates[middleIndex];

      // Provider 상태 업데이트 (build 중 호출 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(calendarSettingsProvider.notifier).setDisplayDate(displayDate);
      });
    }
  }

  /// 캘린더 탭 콜백
  void _onCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment &&
        details.appointments != null &&
        details.appointments!.isNotEmpty) {
      // 일정 탭 (휴일은 Appointment에서 제외됨)
      final appointment = details.appointments!.first as Appointment;
      final appointmentId = appointment.id as String?;

      if (appointmentId != null) {
        _handleScheduleTap(appointmentId);
      }
    } else if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      // 날짜 셀 탭 - 휴일 확인 후 처리
      _handleDateCellTap(details.date!);
    }
  }

  /// 날짜 셀 탭 처리 (휴일 포함)
  void _handleDateCellTap(DateTime date) {
    // 선택 날짜 변경
    ref.read(calendarSettingsProvider.notifier).setSelectedDate(date);

    // 해당 날짜에 일정이 있는지 확인
    final scheduleDataSource = ref.read(scheduleOnlyDataSourceProvider).value;
    final hasAppointments = scheduleDataSource?.appointments
        ?.where((app) => _isSameDay(app.startTime, date))
        .isNotEmpty ?? false;

    // 휴일인지 확인
    final holidayAsync = ref.read(currentHolidaysProvider);
    holidayAsync.whenData((holidays) {
      final holiday = holidays.where((h) {
        final holidayDate = parseHolidayDate(h.locdate);
        return holidayDate != null && _isSameDay(holidayDate, date);
      }).firstOrNull;

      if (holiday != null && context.mounted) {
        // 휴일인 경우 휴일 상세 시트 표시
        showHolidayDetailSheet(context, holiday);
      } else if (!hasAppointments && context.mounted) {
        // 일정이 없는 날짜인 경우 일정 생성 폼 표시
        showScheduleFormSheet(context, initialDate: date);
      }
    });
  }

  /// 일정 탭 처리
  Future<void> _handleScheduleTap(String scheduleId) async {
    // 외부 콜백이 있으면 우선 사용
    if (widget.onScheduleTap != null) {
      widget.onScheduleTap!(scheduleId);
      return;
    }

    // 기본 상세 보기 처리
    try {
      final schedules = await ref.read(filteredSchedulesProvider.future);
      final schedule = schedules.where((s) => s.id == scheduleId).firstOrNull;

      if (schedule != null && context.mounted) {
        // ignore: use_build_context_synchronously
        showScheduleDetailSheet(context, schedule);
      }
    } catch (error) {
      debugPrint('일정 상세 보기 오류: $error');
    }
  }

  /// 캘린더 길게 누르기 콜백
  void _onCalendarLongPress(CalendarLongPressDetails details) {
    if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      // 새 일정 생성
      widget.onDateLongPress?.call(details.date!);
    }
  }

  /// 드래그 앤 드롭 완료 콜백
  void _onDragEnd(AppointmentDragEndDetails details) {
    if (details.appointment == null || details.droppingTime == null) return;

    final appointment = details.appointment as Appointment;
    final appointmentId = appointment.id as String?;
    if (appointmentId == null) return; // 일정만 드래그 가능

    // 시간 차이 계산
    final duration = appointment.endTime.difference(appointment.startTime);
    final newStartTime = details.droppingTime!;
    final newEndTime = newStartTime.add(duration);

    // API 호출로 일정 이동
    ref.read(scheduleMutationsProvider.notifier).moveSchedule(
          appointmentId,
          newStartTime: newStartTime,
          newEndTime: newEndTime,
        );
  }

  /// 리사이즈 완료 콜백
  void _onResizeEnd(AppointmentResizeEndDetails details) {
    if (details.appointment == null) return;

    final appointment = details.appointment as Appointment;
    final appointmentId = appointment.id as String?;
    if (appointmentId == null) return; // 일정만 리사이즈 가능

    // API 호출로 일정 리사이즈
    ref.read(scheduleMutationsProvider.notifier).resizeSchedule(
          appointmentId,
          newStartTime: details.startTime,
          newEndTime: details.endTime!,
        );
  }

  /// 에러 뷰
  Widget _buildErrorView(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '일정을 불러올 수 없습니다',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(scheduleOnlyDataSourceProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 휴일 표시 관련 헬퍼 메서드들
  // ============================================================

  /// 월간 뷰 셀 빌더 - 휴일 표시
  Widget _buildMonthCell(BuildContext context, MonthCellDetails details) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isToday = _isSameDay(details.date, DateTime.now());
    final isCurrentMonth = details.date.month ==
        details.visibleDates[details.visibleDates.length ~/ 2].month;
    final isWeekend = details.date.weekday == DateTime.sunday;

    // 휴일 확인
    final holidayAsync = ref.watch(currentHolidaysProvider);

    return holidayAsync.when(
      data: (holidays) {
        // 현재 날짜에 해당하는 휴일 찾기
        final holiday = holidays.where((h) {
          final holidayDate = parseHolidayDate(h.locdate);
          return holidayDate != null && _isSameDay(holidayDate, details.date);
        }).firstOrNull;

        final isHoliday = holiday != null;
        final isRedDay = isHoliday || isWeekend;

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
              // 날짜 (좌측 상단)
              Positioned(
                left: 4,
                top: 4,
                child: isToday
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          '${details.date.day}',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        '${details.date.day}',
                        style: TextStyle(
                          color: isRedDay
                              ? Colors.red
                              : isCurrentMonth
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: isRedDay ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
              ),

              // 휴일 이름 (우측 상단)
              if (isHoliday)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 60),
                    child: Text(
                      holiday.dateName,
                      style: const TextStyle(
                        color: Colors.red,
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
      },
      loading: () => _buildDefaultMonthCell(context, details),
      error: (error, stack) => _buildDefaultMonthCell(context, details),
    );
  }

  /// 기본 월간 셀 (휴일 로딩 실패 시)
  Widget _buildDefaultMonthCell(BuildContext context, MonthCellDetails details) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isToday = _isSameDay(details.date, DateTime.now());
    final isCurrentMonth = details.date.month ==
        details.visibleDates[details.visibleDates.length ~/ 2].month;
    final isWeekend = details.date.weekday == DateTime.sunday;

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
          // 날짜 (좌측 상단)
          Positioned(
            left: 4,
            top: 4,
            child: isToday
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      '${details.date.day}',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    '${details.date.day}',
                    style: TextStyle(
                      color: isWeekend
                          ? Colors.red
                          : isCurrentMonth
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: isWeekend ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Special Regions 빌더 - 일간/주간 뷰 휴일 표시
  List<TimeRegion> _buildSpecialRegions(CalendarSettingsState settings) {
    final holidayAsync = ref.read(currentHolidaysProvider);

    return holidayAsync.when(
      data: (holidays) {
        return holidays.map((holiday) {
          final holidayDate = parseHolidayDate(holiday.locdate);
          if (holidayDate == null) return null;

          return TimeRegion(
            startTime: holidayDate,
            endTime: holidayDate.add(const Duration(days: 1)),
            text: holiday.dateName,
            color: Colors.red.withValues(alpha: 0.1),
            enablePointerInteraction: false,
            textStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          );
        }).whereType<TimeRegion>().toList();
      },
      loading: () => [],
      error: (error, stack) => [],
    );
  }

  /// 두 날짜가 같은 날인지 확인
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
