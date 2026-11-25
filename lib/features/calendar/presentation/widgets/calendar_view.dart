import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_actions.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view_view.dart';

/// SfCalendar 위젯을 래핑한 캘린더 뷰. 모양은 [CalendarViewWidgetView]
///
/// Riverpod Provider와 연결되어 상태 관리가 자동으로 됩니다.
/// onViewChanged, onTap 등의 콜백이 CalendarSettings와 연결됩니다.
class CalendarViewWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return CalendarViewWidgetView(
      settings: ref.watch(calendarSettingsProvider),
      schedules: ref.watch(scheduleOnlyDataSourceProvider),
      holidays: ref
          .watch(currentHolidaysProvider)
          .whenOrNull(data: (holidays) => holidays),
      onRetry: () => ref.invalidate(currentSchedulesProvider),
      onDisplayDateChanged: (displayDate) => ref
          .read(calendarSettingsProvider.notifier)
          .setDisplayDate(displayDate),
      onScheduleTap: onScheduleTap,
      onMoreTap: (date) => openSchedulesOnDay(context, ref, date),
      onDateTap: (date) => openCalendarDate(context, ref, date),
      onDateLongPress: onDateLongPress,
      onDragEnd: (details) => moveDraggedSchedule(ref, details),
      onResizeEnd: (details) => resizeSchedule(ref, details),
    );
  }
}
