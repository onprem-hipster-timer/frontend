import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/utils/calendar_date_utils.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_month_cell.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_style.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_actions.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_data_source.dart';

/// 빈 CalendarDataSource (로딩용)
class _EmptyDataSource extends ScheduleCalendarDataSource {
  _EmptyDataSource() : super.empty();
}

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

/// 월 보기 위쪽 요일 줄 높이(달력 기본값)
const _monthViewHeaderHeight = 30.0;

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

    _syncController(settings);

    // 불러오는 동안에는 빈 달력 위에 로딩 표시를 겹친다
    final (loaded, error) = ref
        .watch(scheduleOnlyDataSourceProvider)
        .when(
          data: (dataSource) => (dataSource, null),
          loading: () => (null, null),
          error: (error, _) => (null, error),
        );
    if (error != null) {
      return AppErrorState(
        title: '일정을 불러올 수 없습니다',
        error: error,
        onRetry: () => ref.invalidate(currentSchedulesProvider),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 직접 고른 수도 칸에 들어가는 수까지만 쓴다
        final fits = _autoEventsPerDay(context, constraints);
        final chosen = settings.monthEventsPerDay;
        final eventsPerDay = chosen == null || chosen > fits ? fits : chosen;
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
              monthCellBuilder: (context, details) =>
                  CalendarMonthCell(details: details),
              specialRegions: _holidayRegions(),
              onViewChanged: _onViewChanged,
              onTap: _onCalendarTap,
              onLongPress: _onCalendarLongPress,
              onDragEnd: (details) => moveDraggedSchedule(ref, details),
              onAppointmentResizeEnd: (details) => resizeSchedule(ref, details),
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
                    viewType: ref.read(calendarSettingsProvider).viewType,
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

  /// 월 보기 칸 높이에 맞는 일정 수. 위쪽 요일 줄을 뺀 높이를 주 수로 나눠 칸 높이를 구한다
  int _autoEventsPerDay(BuildContext context, BoxConstraints constraints) =>
      autoMonthEventsPerDay(
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
    } else if (details.targetElement == CalendarElement.moreAppointmentRegion &&
        details.date != null) {
      // "+N more" 탭 → 바텀시트 일정 리스트
      openSchedulesOnDay(context, ref, details.date!);
    } else if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      // 날짜 셀 탭 - 휴일 확인 후 처리
      openCalendarDate(context, ref, details.date!);
    }
  }

  /// 일정을 누르면 [CalendarViewWidget.onScheduleTap]을, 없으면 일정 상세로 간다
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
  List<TimeRegion>? _holidayRegions() => ref
      .watch(currentHolidaysProvider)
      .whenOrNull(
        data: (holidays) =>
            calendarHolidayRegions(holidays, AppColors.of(context).holiday),
      );

  /// 캘린더 길게 누르기 콜백
  void _onCalendarLongPress(CalendarLongPressDetails details) {
    if (details.targetElement == CalendarElement.calendarCell &&
        details.date != null) {
      // 새 일정 생성
      widget.onDateLongPress?.call(details.date!);
    }
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
