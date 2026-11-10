import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/date_symbol_data_local.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart' show setUpAll;
import 'package:momeet/features/calendar/presentation/pages/calendar_page.dart';
import 'package:momeet/features/calendar/presentation/pages/schedule_detail_page.dart';
import 'package:momeet/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:momeet/features/calendar/presentation/providers/schedule_detail_providers.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/holiday_detail_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_list_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';

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

  List<ScheduleRead> schedules(String text) => [
    for (var i = 0; i < 4; i++)
      makeSchedule(
        id: 'schedule-$i',
        title: text,
        description: text,
        startTime: DateTime(2026, 4, 8, 9 + i * 2),
        endTime: DateTime(2026, 4, 8, 10 + i * 2),
        tags: [makeTag(id: 'tag-$i', name: text)],
      ),
    makeSchedule(
      id: 'schedule-long',
      title: text,
      startTime: DateTime(2026, 4, 6),
      endTime: DateTime(2026, 4, 10),
    ),
  ];

  HolidayItem holiday(String name) => HolidayItem(
    locdate: '20260408',
    seq: 1,
    dateKind: '01',
    dateName: name,
    isHoliday: true,
  );

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
    currentHolidaysProvider.overrideWith((ref) async => [holiday(text)]),
  ];

  for (final viewType in [
    CalendarViewType.month,
    CalendarViewType.week,
    CalendarViewType.day,
  ]) {
    testLayoutAudit(
      'calendar_page_${viewType.name}',
      subject: '${viewType.name} 보기 일정·공휴일',
      build: (text) => wrapWithApp(
        overrides: calendarOverrides(text.value, viewType),
      )(const CalendarPage()),
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
        wrapWithApp()(HolidayDetailSheet(holiday: holiday(text.value))),
  );
}

class _FixedSettings extends CalendarSettings {
  _FixedSettings(this.initial);

  final CalendarSettingsState initial;

  @override
  CalendarSettingsState build() => initial;
}
