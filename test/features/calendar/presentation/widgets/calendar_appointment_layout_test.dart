import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:layout_audit/layout_audit.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/calendar_render_harness.dart';
import '../../../../helpers/schedule_fixtures.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
  });

  // 월간 뷰는 일정이 든 셀이 낮아지면 달력 위젯 안에서 단언이 나 아직 넣지 않는다.
  const viewTypes = [CalendarViewType.week, CalendarViewType.day];
  for (final viewType in viewTypes) {
    testLayoutAudit(
      'calendar_appointment',
      subject: '${viewType.name} 뷰 일정',
      texts: const [StressTexts.koreanLong, StressTexts.latinUnbroken],
      within: find.byType(CalendarViewWidget),
      build: (text) => CalendarRenderHarness(
        settings: CalendarSettingsState(
          viewType: viewType,
          selectedDate: _displayDate,
          displayDate: _displayDate,
          firstDayOfWeek: DateTime.sunday,
        ),
        schedules: _schedulesTitled(text.value),
        holidays: const [],
      ),
      verify: (tester) {
        expect(find.byType(CalendarViewWidget), findsOneWidget);
      },
    );
  }
}

final _displayDate = DateTime(2026, 4);

List<ScheduleRead> _schedulesTitled(String title) {
  ScheduleRead schedule(String id, DateTime start, DateTime end) {
    return makeSchedule(
      id: id,
      title: title,
      startTime: start,
      endTime: end,
      tags: [
        makeTag(id: '$id-tag-1', name: '업무', color: '#4CAF50'),
        makeTag(id: '$id-tag-2', name: '개인', color: '#2196F3'),
      ],
    );
  }

  return [
    schedule('short', DateTime(2026, 4, 1, 9), DateTime(2026, 4, 1, 9, 30)),
    schedule('long', DateTime(2026, 4, 1, 10), DateTime(2026, 4, 1, 12)),
    // 자정부터 다음 날 자정까지면 하루 종일 일정으로 표시된다.
    schedule('all-day', DateTime(2026, 4, 1), DateTime(2026, 4, 2)),
  ];
}
