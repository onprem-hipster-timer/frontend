import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../../helpers/calendar_render_harness.dart';
import '../../../../helpers/schedule_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  group('CalendarView 렌더링', () {
    testWidgets('주요 뷰 타입별로 렌더링된다', variant: _calendarViewVariant, (
      tester,
    ) async {
      await _pumpCalendar(tester, viewType: _calendarViewVariant.currentValue!);

      expectNoFlutterError(tester);
      expect(find.byType(CalendarViewWidget), findsOneWidget);
    });

    testWidgets(
      '대표 화면 크기별로 월간 뷰가 렌더링된다',
      variant: TestViewportVariants.renderSmoke,
      (tester) async {
        await _pumpCalendar(
          tester,
          viewport: TestViewportVariants.renderSmoke.currentValue!,
        );

        expectNoFlutterError(tester);
        expect(find.byType(CalendarViewWidget), findsOneWidget);
      },
    );

    testWidgets('월간 뷰는 일요일 시작 설정을 SfCalendar에 전달한다', (tester) async {
      await _pumpCalendar(tester);

      final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));

      expect(calendar.firstDayOfWeek, DateTime.sunday);
    });

    testWidgets('isHoliday=true인 항목만 공휴일 라벨로 렌더링된다', (tester) async {
      await _pumpCalendar(tester);

      expect(find.text('선거일'), findsAtLeastNWidgets(1));
      expect(find.text('비공휴 기념일'), findsNothing);
    });

    testWidgets('일요일 날짜는 공휴일 데이터와 무관하게 빨간색으로 렌더링된다', (tester) async {
      await _pumpCalendar(tester);

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

Future<void> _pumpCalendar(
  WidgetTester tester, {
  CalendarViewType viewType = CalendarViewType.month,
  TestViewport viewport = TestViewports.desktop16x10,
}) => tester.pumpCalendar(
  displayDate: _displayDate,
  schedules: _sampleSchedules(),
  holidays: _sampleHolidays,
  viewType: viewType,
  viewport: viewport,
);

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
