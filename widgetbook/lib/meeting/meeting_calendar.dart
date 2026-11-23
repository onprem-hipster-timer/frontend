import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_calendar.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

@widgetbook.UseCase(
  name: '모임 날짜 달력',
  type: MeetingCalendar,
  path: '[모임]/모임 만들기',
)
Widget meetingCalendar(BuildContext context) {
  final stage = context.knobs.object.dropdown(
    label: '고르는 중',
    description: '오늘은 3월 2일로 둔다(그 앞은 고를 수 없다). 날을 누르면 앱처럼 바뀐다',
    options: const ['기간: 아직 안 고름', '기간: 시작일 고름', '제외할 날: 하루 뺌'],
  );
  final initial = switch (stage) {
    '기간: 시작일 고름' => meetingFlowAt(
      MeetingQuestion.range,
    ).tapDay(meetingSampleDay(8)),
    '제외할 날: 하루 뺌' => meetingFlowAt(
      MeetingQuestion.exclusions,
    ).tapDay(meetingSampleDay(10)),
    _ => meetingFlowAt(MeetingQuestion.range),
  };
  return MeetingFlowHost(
    key: ValueKey(stage),
    initial: initial,
    builder: (context, flow, onChanged, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MeetingCalendar(
        firstDay: meetingSampleToday,
        shownDay:
            flow.rangeStart ??
            (flow.draft.dates.isEmpty ? null : flow.draft.dates.first),
        stateOf: (day) => flow.dayState(day, today: meetingSampleToday),
        onDayTap: (day) => onChanged(flow.tapDay(day)),
      ),
    ),
  );
}
