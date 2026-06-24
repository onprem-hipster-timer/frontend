import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../helpers/rendering_test_devices.dart';
import '../../../../helpers/schedule_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  group('CalendarView 렌더링', () {
    testWidgets('주요 뷰 타입별로 렌더링된다', variant: _calendarViewVariant, (
      tester,
    ) async {
      await tester.pumpCalendar(viewType: _calendarViewVariant.currentValue!);

      expectNoFlutterError(tester);
      expect(find.byType(CalendarViewWidget), findsOneWidget);
    });

    testWidgets(
      '대표 화면 크기별로 월간 뷰가 렌더링된다',
      variant: TestViewportVariants.renderSmoke,
      (tester) async {
        await tester.pumpCalendar(
          viewport: TestViewportVariants.renderSmoke.currentValue!,
        );

        expectNoFlutterError(tester);
        expect(find.byType(CalendarViewWidget), findsOneWidget);
      },
    );

    testWidgets('월간 뷰는 일요일 시작 설정을 SfCalendar에 전달한다', (tester) async {
      await tester.pumpCalendar();

      final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));

      expect(calendar.firstDayOfWeek, DateTime.sunday);
    });

    testWidgets('isHoliday=true인 항목만 공휴일 라벨로 렌더링된다', (tester) async {
      await tester.pumpCalendar();

      expect(find.text('선거일'), findsAtLeastNWidgets(1));
      expect(find.text('비공휴 기념일'), findsNothing);
    });

    testWidgets('일요일 날짜는 공휴일 데이터와 무관하게 빨간색으로 렌더링된다', (tester) async {
      await tester.pumpCalendar();

      final redSundayDateExists = tester
          .widgetList<Text>(find.text('5'))
          .any((text) => text.style?.color == Colors.red);

      expect(redSundayDateExists, isTrue);
    });
  });
}

final _calendarViewVariant = ValueVariant<CalendarViewType>({
  CalendarViewType.month,
  CalendarViewType.week,
  CalendarViewType.day,
  CalendarViewType.agenda,
});

final _displayDate = DateTime(2026, 4);

extension _CalendarPump on WidgetTester {
  Future<void> pumpCalendar({
    CalendarViewType viewType = CalendarViewType.month,
    TestViewport viewport = TestViewports.desktop16x10,
  }) async {
    setTestViewport(viewport);

    await pumpWidget(
      _CalendarRenderHarness(
        settings: CalendarSettingsState(
          viewType: viewType,
          selectedDate: _displayDate,
          displayDate: _displayDate,
          firstDayOfWeek: DateTime.sunday,
        ),
        schedules: _sampleSchedules(),
        holidays: _sampleHolidays,
      ),
    );
    await pumpStableFrames();
  }
}

List<ScheduleRead> _sampleSchedules() {
  return [
    makeSchedule(
      id: 'schedule-1',
      title: '오전 회의',
      startTime: DateTime(2026, 4, 1, 9),
      endTime: DateTime(2026, 4, 1, 10),
      tags: [makeTag(name: '업무', color: '#4CAF50')],
    ),
  ];
}

const _sampleHolidays = [
  HolidayItem(
    locdate: '20260401',
    seq: 1,
    dateKind: '01',
    dateName: '선거일',
    isHoliday: true,
  ),
  HolidayItem(
    locdate: '20260403',
    seq: 1,
    dateKind: '99',
    dateName: '비공휴 기념일',
    isHoliday: false,
  ),
];

class _CalendarRenderHarness extends StatelessWidget {
  const _CalendarRenderHarness({
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
          () => _TestCalendarSettings(settings),
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

class _TestCalendarSettings extends CalendarSettings {
  _TestCalendarSettings(this.initialState);

  final CalendarSettingsState initialState;

  @override
  CalendarSettingsState build() => initialState;
}
