import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/features/calendar/domain/holidays.dart';
import 'package:momeet/features/calendar/presentation/utils/calendar_date_utils.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart'
    as fmt;
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell_view.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_style.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';

/// 빈 CalendarDataSource (로딩용)
class _EmptyDataSource extends ScheduleCalendarDataSource {
  _EmptyDataSource() : super.empty();
}

/// SfCalendar 위젯을 래핑한 캘린더 뷰
///
/// [settings]의 보기·고른 날·보는 날로 달력을 그리고, 보는 기간이 바뀌거나 칸·일정을 누르고 끌면 그 콜백을 부른다.
/// 일정을 불러오는 동안에는 빈 달력 위에 로딩 표시를 겹치고, 못 불러오면 [onRetry]를 둔 오류 화면을 보인다.
class CalendarViewWidgetView extends StatefulWidget {
  const CalendarViewWidgetView({
    super.key,
    required this.settings,
    required this.schedules,
    required this.holidays,
    required this.onRetry,
    required this.onDisplayDateChanged,
    this.onScheduleTap,
    required this.onMoreTap,
    required this.onDateTap,
    this.onDateLongPress,
    required this.onDragEnd,
    required this.onResizeEnd,
  });

  final CalendarSettingsState settings;
  final AsyncValue<ScheduleCalendarDataSource> schedules;

  /// 보는 기간의 공휴일. 불러오는 중이거나 못 불러오면 null
  final List<HolidayItem>? holidays;
  final VoidCallback onRetry;

  /// 보는 기간이 바뀌면 그 가운데 날짜로 부른다
  final ValueChanged<DateTime> onDisplayDateChanged;

  /// 일정을 탭했을 때 콜백
  final void Function(String scheduleId)? onScheduleTap;

  /// 월 보기 칸의 "+N"을 누른 날
  final ValueChanged<DateTime> onMoreTap;

  /// 누른 날짜 칸
  final ValueChanged<DateTime> onDateTap;

  /// 날짜를 길게 눌렀을 때 콜백 (새 일정 생성용)
  final void Function(DateTime date)? onDateLongPress;
  final ValueChanged<AppointmentDragEndDetails> onDragEnd;
  final ValueChanged<AppointmentResizeEndDetails> onResizeEnd;

  @override
  State<CalendarViewWidgetView> createState() => _CalendarViewWidgetViewState();
}

/// 월 보기 위쪽 요일 줄 높이(달력 기본값)
const _monthViewHeaderHeight = 30.0;

class _CalendarViewWidgetViewState extends State<CalendarViewWidgetView> {
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
    final settings = widget.settings;

    _syncController(settings);

    // 불러오는 동안에는 빈 달력 위에 로딩 표시를 겹친다
    final (loaded, error) = widget.schedules.when(
      data: (dataSource) => (dataSource, null),
      loading: () => (null, null),
      error: (error, _) => (null, error),
    );
    if (error != null) {
      return AppErrorState(
        title: '일정을 불러올 수 없습니다',
        error: error,
        onRetry: widget.onRetry,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final eventsPerDay = _eventsPerDay(context, constraints, settings);
        return Stack(
          children: [
            SfCalendar(
              controller: _calendarController,
              dataSource: loaded ?? _EmptyDataSource(),
              view: settings.viewType.toSfCalendarView(),
              firstDayOfWeek: settings.firstDayOfWeek,
              showNavigationArrow: false, // 커스텀 네비게이션 사용
              showDatePickerButton: false,
              showCurrentTimeIndicator: true,
              allowViewNavigation: true,
              allowDragAndDrop: true,
              allowAppointmentResize: true,
              monthCellBuilder: (context, details) => _MonthCell(
                details: details,
                highlightWeekends: settings.highlightWeekends,
                holidays: widget.holidays,
              ),
              specialRegions: _holidayRegions(),
              onViewChanged: _onViewChanged,
              onTap: _onCalendarTap,
              onLongPress: _onCalendarLongPress,
              onDragEnd: widget.onDragEnd,
              onAppointmentResizeEnd: widget.onResizeEnd,
              backgroundColor: colorScheme.surface,
              cellBorderColor: colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
              todayHighlightColor: colorScheme.primary,
              // 기간 이름과 이동은 화면의 도구 줄이 맡는다
              headerHeight: 0,
              viewHeaderStyle: calendarViewHeaderStyle(colorScheme),
              selectionDecoration: calendarSelectionDecoration(colorScheme),
              monthViewSettings: calendarMonthViewSettings(
                colorScheme,
                eventsPerDay,
              ),
              timeSlotViewSettings: calendarTimeSlotViewSettings(
                colorScheme,
                use24HourFormat: settings.use24HourFormat,
                textScaler: MediaQuery.textScalerOf(context),
              ),
              scheduleViewSettings: calendarScheduleViewSettings(colorScheme),
              appointmentBuilder: (context, details) =>
                  ScheduleAppointmentBlock(
                    details: details,
                    viewType: settings.viewType,
                  ),
            ),

            if (loaded == null) const Positioned.fill(child: _LoadingVeil()),
          ],
        );
      },
    );
  }

  /// 컨트롤러를 설정 상태(보기·고른 날·보는 날)에 맞춘다
  void _syncController(CalendarSettingsState settings) {
    _calendarController
      ..view = settings.viewType.toSfCalendarView()
      ..selectedDate = settings.selectedDate
      ..displayDate = settings.displayDate;
  }

  /// 월 보기 칸 하나에 보일 일정 수. 직접 고른 수도 칸에 들어가는 수까지만 쓴다
  int _eventsPerDay(
    BuildContext context,
    BoxConstraints constraints,
    CalendarSettingsState settings,
  ) {
    final fits = _autoEventsPerDay(context, constraints);
    final chosen = settings.monthEventsPerDay;
    return chosen == null || chosen > fits ? fits : chosen;
  }

  /// 월 보기 칸 높이에 맞는 일정 수. 위쪽 요일 줄을 뺀 높이를 주 수로 나눠 칸 높이를 구한다
  int _autoEventsPerDay(BuildContext context, BoxConstraints constraints) =>
      autoMonthEventsPerDay(
        cellWidth: constraints.maxWidth / DateTime.daysPerWeek,
        cellHeight:
            (constraints.maxHeight - _monthViewHeaderHeight) / monthWeeksInView,
        textScale: MediaQuery.textScalerOf(context).scale(1),
      );

  /// 뷰 변경 콜백
  void _onViewChanged(ViewChangedDetails details) {
    // 표시 날짜 범위가 변경되었을 때
    if (details.visibleDates.isNotEmpty) {
      final middleIndex = details.visibleDates.length ~/ 2;
      final displayDate = details.visibleDates[middleIndex];

      // Provider 상태 업데이트 (build 중 호출 방지)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDisplayDateChanged(displayDate);
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
    } else if (details.targetElement == CalendarElement.moreAppointmentRegion &&
        details.date != null) {
      // "+N more" 탭 → 바텀시트 일정 리스트
      widget.onMoreTap(details.date!);
    } else if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      // 날짜 셀 탭 - 휴일 확인 후 처리
      widget.onDateTap(details.date!);
    }
  }

  /// 일정을 누르면 [CalendarViewWidgetView.onScheduleTap]을, 없으면 일정 상세로 간다
  void _handleScheduleTap(String scheduleId) {
    final onScheduleTap = widget.onScheduleTap;
    if (onScheduleTap != null) {
      onScheduleTap(scheduleId);
      return;
    }
    context.pushNamed(
      AppRoute.scheduleDetail.name,
      queryParameters: {'id': scheduleId},
    );
  }

  /// 일·주 보기의 공휴일 구역. build에서 부르므로 공휴일을 나중에 불러와도 반영된다
  List<TimeRegion>? _holidayRegions() => switch (widget.holidays) {
    final holidays? => calendarHolidayRegions(
      holidays,
      AppColors.of(context).holiday,
    ),
    null => null,
  };

  /// 캘린더 길게 누르기 콜백
  void _onCalendarLongPress(CalendarLongPressDetails details) {
    if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      // 새 일정 생성
      widget.onDateLongPress?.call(details.date!);
    }
  }
}

/// 월 보기의 날짜 칸. 공휴일을 불러오는 중이거나 못 불러오면 날짜만 보인다
class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.details,
    required this.highlightWeekends,
    required this.holidays,
  });

  final MonthCellDetails details;
  final bool highlightWeekends;
  final List<HolidayItem>? holidays;

  @override
  Widget build(BuildContext context) {
    final date = details.date;
    final visible = details.visibleDates;
    final holidays = this.holidays;
    return CalendarMonthCellView(
      date: date,
      isToday: fmt.isSameDay(date, DateTime.now()),
      isCurrentMonth: date.month == visible[visible.length ~/ 2].month,
      highlightWeekends: highlightWeekends,
      holidayName: holidays == null
          ? null
          : holidayOn(holidays, date)?.dateName,
    );
  }
}

/// 일정을 불러오는 동안 달력 위에 겹치는 흐린 막과 로딩 표시
class _LoadingVeil extends StatelessWidget {
  const _LoadingVeil();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      child: const AppLoading(),
    );
  }
}
