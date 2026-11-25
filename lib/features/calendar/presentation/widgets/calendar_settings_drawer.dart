import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_settings_drawer_view.dart';

/// 달력 보기 설정 서랍. 바꾼 값은 기기에 저장한다. 모양은 [CalendarSettingsDrawerView]
///
/// [header]를 주면 맨 위에 둔다(예: 낮은 화면의 화면 이동).
class CalendarSettingsDrawer extends ConsumerWidget {
  const CalendarSettingsDrawer({super.key, this.header});

  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(calendarSettingsProvider);
    final notifier = ref.read(calendarSettingsProvider.notifier);
    return CalendarSettingsDrawerView(
      header: header,
      settings: settings,
      onShowHolidaysChanged: notifier.setShowHolidays,
      onHighlightWeekendsChanged: notifier.setHighlightWeekends,
      onUse24HourFormatChanged: notifier.setUse24HourFormat,
      onFirstDayOfWeekChanged: notifier.setFirstDayOfWeek,
      onMonthEventsPerDayChanged: notifier.setMonthEventsPerDay,
    );
  }
}
