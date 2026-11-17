import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/calendar/presentation/widgets/schedule_form_sheet.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';

/// 일정 만들기 시트에 넣을 기기 시각. 기기 시간대로 0시부터 0시까지인 날들이면 마지막 날 23:59에 끝내
/// 일정 폼의 종일 모양으로 연다
///
/// 테스트: test/features/meeting/presentation/utils/meeting_schedule_test.dart
({DateTime start, DateTime end}) scheduleRangeOf(TimeSpan span) {
  final start = span.start.toLocal();
  final end = span.end.toLocal();
  bool midnight(DateTime t) => t.hour == 0 && t.minute == 0;
  return midnight(start) && midnight(end)
      ? (start: start, end: end.subtract(const Duration(minutes: 1)))
      : (start: start, end: end);
}

/// [run]의 시간으로 내 달력의 일정 만들기 시트를 연다. 제목은 모임 제목이다
Future<void> addMeetingRunToCalendar(
  BuildContext context,
  MeetingBoard board,
  MeetingRun run,
) {
  final range = scheduleRangeOf(board.grid.spanOf(run.cells));
  return showScheduleFormSheet(
    context,
    initialStartTime: range.start,
    initialEndTime: range.end,
    initialTitle: board.meeting.title,
  );
}
