import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 달력 렌더링 테스트가 공유하는 하네스. 설정·일정·공휴일을 고정값으로 주입한다.
class CalendarRenderHarness extends StatelessWidget {
  const CalendarRenderHarness({
    super.key,
    required this.settings,
    required this.schedules,
    required this.holidays,
  });

  final CalendarSettingsState settings;
  final List<ScheduleRead> schedules;
  final List<HolidayItem> holidays;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        calendarSettingsProvider.overrideWith(
          () => _FixedCalendarSettings(settings),
        ),
        currentSchedulesProvider.overrideWith((ref) => Future.value(schedules)),
        currentHolidaysProvider.overrideWith((ref) => Future.value(holidays)),
      ],
      child: MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(body: CalendarViewWidget()),
      ),
    );
  }
}

class _FixedCalendarSettings extends CalendarSettings {
  _FixedCalendarSettings(this.initialState);

  final CalendarSettingsState initialState;

  @override
  CalendarSettingsState build() => initialState;
}

extension CalendarRenderPump on WidgetTester {
  Future<void> pumpCalendar({
    required DateTime displayDate,
    required List<ScheduleRead> schedules,
    required List<HolidayItem> holidays,
    CalendarViewType viewType = CalendarViewType.month,
    TestViewport viewport = TestViewports.desktop16x10,
  }) async {
    setTestViewport(viewport);

    await pumpWidget(
      CalendarRenderHarness(
        settings: CalendarSettingsState(
          viewType: viewType,
          selectedDate: displayDate,
          displayDate: displayDate,
          firstDayOfWeek: DateTime.sunday,
        ),
        schedules: schedules,
        holidays: holidays,
      ),
    );
    await pumpStableFrames();
  }
}
