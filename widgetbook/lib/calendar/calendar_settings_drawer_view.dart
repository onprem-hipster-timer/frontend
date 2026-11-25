import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_settings_drawer_view.dart';
import 'package:momeet/shared/widgets/shell_tab_list.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_plan.dart';

@widgetbook.UseCase(
  name: '달력 보기 설정 서랍',
  type: CalendarSettingsDrawerView,
  path: '[달력]',
)
Widget calendarSettingsDrawerView(BuildContext context) {
  final tabs = context.knobs.boolean(
    label: '탭 목록 함께',
    description: '아주 작은 화면(접는 폰 덮개 화면 등)에서는 서랍 맨 위에 탭 목록을 둔다',
  );
  // 앱에서는 달력 화면 도구 줄의 설정 버튼을 누르면 왼쪽에서 열린다. 바꾼 값은 바로 보인다
  return Align(
    alignment: Alignment.centerLeft,
    child: _Drawer(tabs: tabs),
  );
}

/// 바꾼 설정이 바로 보이도록 값을 들고 있는다
class _Drawer extends StatefulWidget {
  const _Drawer({required this.tabs});

  final bool tabs;

  @override
  State<_Drawer> createState() => _DrawerState();
}

class _DrawerState extends State<_Drawer> {
  var _settings = CalendarSettingsState(
    selectedDate: planStamp,
    displayDate: DateTime(planStamp.year, planStamp.month),
    firstDayOfWeek: DateTime.sunday,
  );

  void _set(CalendarSettingsState settings) =>
      setState(() => _settings = settings);

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return CalendarSettingsDrawerView(
      header: widget.tabs ? ShellTabList(current: 0, onSelect: (_) {}) : null,
      settings: settings,
      onShowHolidaysChanged: (value) =>
          _set(settings.copyWith(showHolidays: value)),
      onHighlightWeekendsChanged: (value) =>
          _set(settings.copyWith(highlightWeekends: value)),
      onUse24HourFormatChanged: (value) =>
          _set(settings.copyWith(use24HourFormat: value)),
      onFirstDayOfWeekChanged: (value) =>
          _set(settings.copyWith(firstDayOfWeek: value)),
      onMonthEventsPerDayChanged: (value) =>
          _set(settings.copyWith(monthEventsPerDay: value)),
    );
  }
}
