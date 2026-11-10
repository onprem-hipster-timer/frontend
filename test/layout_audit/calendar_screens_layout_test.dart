import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/date_symbol_data_local.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/holiday_detail_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_appointment_block.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../helpers/layout_audit_app.dart';
import '../helpers/schedule_fixtures.dart';
import '../helpers/timer_fixtures.dart';

/// 달력 화면과 일정 시트를 화면 크기 × 글자 배율 × 긴 문구로 점검한다.
///
/// 사용자가 넣는 글자(일정 제목·설명·태그 이름, 공휴일 이름)에 [StressText]를 넣는다.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  final day = DateTime(2026, 4, 8);

  // 하루(4월 8일)에 제목이 서로 다른 일정 넷과 여러 날에 걸친 일정 하나가 겹친다.
  // 첫 일정만 스트레스 문구이고 나머지는 짧은 앱 밖 제목이라, 접히거나 사라지는 제목을 서로 가를 수 있다.
  const otherTitles = ['팀 회의', '고객 미팅', '보고서 마감'];
  List<ScheduleRead> schedules(String text) => [
    for (var i = 0; i < 4; i++)
      makeSchedule(
        id: 'schedule-$i',
        title: i == 0 ? text : otherTitles[i - 1],
        description: text,
        startTime: DateTime(2026, 4, 8, 9 + i * 2),
        endTime: DateTime(2026, 4, 8, 10 + i * 2),
        tags: [makeTag(id: 'tag-$i', name: text)],
      ),
    makeSchedule(
      id: 'schedule-long',
      title: '출장',
      startTime: DateTime(2026, 4, 6),
      endTime: DateTime(2026, 4, 10),
    ),
  ];

  // 일정이 몰린 날(8일)과 그 다음 이틀(9·10일)에 공휴일이 이어진다.
  List<HolidayItem> holidays(String text) => [
    for (final (day, name) in [(8, text), (9, '식목일'), (10, '대체공휴일')])
      HolidayItem(
        locdate: '202604${day.toString().padLeft(2, '0')}',
        seq: 1,
        dateKind: '01',
        dateName: name,
        isHoliday: true,
      ),
  ];

  List<Override> calendarOverrides(String text, CalendarViewType viewType) => [
    calendarSettingsProvider.overrideWith(
      () => _FixedSettings(
        CalendarSettingsState(
          viewType: viewType,
          selectedDate: day,
          displayDate: day,
          firstDayOfWeek: DateTime.sunday,
        ),
      ),
    ),
    currentSchedulesProvider.overrideWith((ref) async => schedules(text)),
    currentHolidaysProvider.overrideWith((ref) async => holidays(text)),
  ];

  for (final viewType in [
    CalendarViewType.month,
    CalendarViewType.week,
    CalendarViewType.day,
  ]) {
    testLayoutAudit(
      'calendar_page_${viewType.name}',
      subject: '${viewType.name} 보기 일정·공휴일',
      // 칸에 다 들어가지 않는 일정 제목은 +N으로 접히는 것이 설계다.
      // 접혀도 빠진 일정이 없는지는 verify의 expectNoHiddenSchedule이 센다.
      scale: ScaleAuditOptions(ignore: _isFoldedSchedule),
      build: (text) => wrapWithApp(
        overrides: calendarOverrides(text.value, viewType),
      )(const CalendarPage()),
      verify: (tester) {
        expectNoHiddenSchedule(tester);
        if (viewType == CalendarViewType.month) {
          // 일정이 몰린 날과 이어지는 공휴일 이름이 칸에 남아 있다
          for (final name in ['식목일', '대체공휴일']) {
            expect(find.text(name), findsWidgets);
          }
        }
      },
    );
  }

  testLayoutAudit(
    'schedule_detail_page',
    subject: '일정 제목·설명·태그',
    build: (text) => wrapWithApp(
      overrides: [
        scheduleDetailProvider(
          'schedule-0',
        ).overrideWith((ref) async => schedules(text.value).first),
        scheduleTimersProvider('schedule-0').overrideWith(
          (ref) async => [
            makeTimer(
              id: 'timer-1',
              status: TimerStatus.completed,
              elapsedTime: 1800,
            ),
          ],
        ),
      ],
    )(const ScheduleDetailPage(scheduleId: 'schedule-0')),
  );

  testLayoutAudit(
    'schedule_form_sheet',
    subject: '일정 제목·설명',
    build: (text) => wrapWithApp()(
      SingleChildScrollView(
        child: ScheduleFormSheet(existingSchedule: schedules(text.value).first),
      ),
    ),
  );

  testLayoutAudit(
    'schedule_list_sheet',
    subject: '일정 제목',
    build: (text) => wrapWithApp()(
      ScheduleListSheet(date: day, schedules: schedules(text.value)),
    ),
  );

  testLayoutAudit(
    'holiday_detail_sheet',
    subject: '공휴일 이름',
    build: (text) =>
        wrapWithApp()(HolidayDetailSheet(holiday: holidays(text.value).first)),
  );
}

class _FixedSettings extends CalendarSettings {
  _FixedSettings(this.initial);

  final CalendarSettingsState initial;

  @override
  CalendarSettingsState build() => initial;
}

/// 4월 8일에 겹친 일정 다섯이 화면에서 모두 셀 수 있다. 일정 막대는 하나, +N 막대는 N으로 센다.
/// 칸이 낮아 점으로만 보이는 월 보기는 뺀다
void expectNoHiddenSchedule(WidgetTester tester) {
  final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
  if (calendar.view == CalendarView.month &&
      calendar.monthViewSettings.appointmentDisplayMode ==
          MonthAppointmentDisplayMode.indicator) {
    return;
  }
  final more = RegExp(r'^\+(\d+)$');
  var counted = 0;
  for (final block in find.byType(ScheduleAppointmentBlock).evaluate()) {
    final texts = find.descendant(
      of: find.byWidget(block.widget),
      matching: find.byType(Text),
    );
    final count = [
      for (final text in tester.widgetList<Text>(texts))
        if (more.firstMatch(text.data ?? '') case final match?)
          int.parse(match.group(1)!),
    ];
    counted += count.isEmpty ? 1 : count.single;
  }
  expect(counted, greaterThanOrEqualTo(5), reason: '막대와 +N으로 셀 수 없는 일정이 있다');
}

bool _isFoldedSchedule(LayoutFinding finding) =>
    finding.kind == LayoutFindingKind.scaleVanished &&
    finding.locations.any(
      (location) =>
          location != null &&
          (location.file.endsWith('schedule_appointment_block.dart') ||
              location.file.endsWith('marquee_text.dart')),
    );
