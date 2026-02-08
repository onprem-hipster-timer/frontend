import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_appointment_builder.dart'
    as custom_builder;
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';

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
    final dataSourceAsync = ref.watch(calendarDataSourceProvider);

    // 컨트롤러와 Provider 상태 동기화
    _calendarController.view = settings.viewType.toSfCalendarView();
    _calendarController.selectedDate = settings.selectedDate;
    _calendarController.displayDate = settings.displayDate;

    return dataSourceAsync.when(
      data: (dataSource) => _buildCalendar(context, settings, dataSource),
      loading: () => _buildCalendar(
        context,
        settings,
        ScheduleCalendarDataSource.empty(),
        isLoading: true,
      ),
      error: (error, stack) => _buildErrorView(context, error),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    CalendarSettingsState settings,
    ScheduleCalendarDataSource dataSource, {
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
      // 일정 탭
      final appointment = details.appointments!.first as Appointment;
      final scheduleId = appointment.id as String?;
      if (scheduleId != null && widget.onScheduleTap != null) {
        widget.onScheduleTap!(scheduleId);
      }
    } else if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      // 날짜 셀 탭 - 선택 날짜 변경
      ref.read(calendarSettingsProvider.notifier).setSelectedDate(details.date!);
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
    final scheduleId = appointment.id as String?;
    if (scheduleId == null) return;

    // 시간 차이 계산
    final duration = appointment.endTime.difference(appointment.startTime);
    final newStartTime = details.droppingTime!;
    final newEndTime = newStartTime.add(duration);

    // API 호출로 일정 이동
    ref.read(scheduleMutationsProvider.notifier).moveSchedule(
          scheduleId,
          newStartTime: newStartTime,
          newEndTime: newEndTime,
        );
  }

  /// 리사이즈 완료 콜백
  void _onResizeEnd(AppointmentResizeEndDetails details) {
    if (details.appointment == null) return;

    final appointment = details.appointment as Appointment;
    final scheduleId = appointment.id as String?;
    if (scheduleId == null) return;

    // API 호출로 일정 리사이즈
    ref.read(scheduleMutationsProvider.notifier).resizeSchedule(
          scheduleId,
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
              ref.invalidate(calendarDataSourceProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
