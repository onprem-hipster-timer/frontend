import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_hours_question.dart';
import 'package:momeet_widgetbook/meeting/samples_meeting_b.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '하루 시간 범위 질문',
  type: MeetingHoursQuestion,
  path: '[모임]/모임 만들기',
)
Widget meetingHoursQuestion(BuildContext context) {
  final knobs = context.knobs;
  final picking = knobs.boolean(
    label: '시각 고르는 중',
    description: "'아니요'를 누르면 시작·끝 시각을 고르는 모양으로 바뀐다",
  );
  final timezone = knobs.object.dropdown(
    label: '시간 기준',
    description: '기기 시간대를 아직 모르면 줄이 없다',
    options: const ['한국 시간', '모름'],
  );
  final flow = MeetingFlow(
    draft: MeetingDraft(
      dates: MeetingDates.range(
        DateTime.utc(2027, 3, 2),
        DateTime.utc(2027, 3, 5),
      ),
    ),
    answered: const {
      MeetingQuestion.range,
      MeetingQuestion.exclusions,
      MeetingQuestion.mode,
    },
    pickingHours: picking,
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: MeetingSampleHolder<MeetingFlow>(
      key: ValueKey(picking),
      initial: flow,
      builder: (flow, onChanged) => MeetingHoursQuestion(
        flow: flow,
        timezone: timezone == '모름' ? null : 'Asia/Seoul',
        onChanged: onChanged,
      ),
    ),
  );
}
