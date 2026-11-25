import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_answer_summary.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

@widgetbook.UseCase(
  name: '답한 질문 요약',
  type: MeetingAnswerSummary,
  path: '[모임]/모임 만들기',
)
Widget meetingAnswerSummary(BuildContext context) {
  final knobs = context.knobs;
  final current = knobs.object.dropdown(
    label: '지금 질문',
    description: '요약은 지금 질문 위에 그 앞까지 답한 것만 보인다. 날짜를 묻는 동안은 날짜 줄이 없다',
    options: const [
      MeetingQuestion.exclusions,
      MeetingQuestion.mode,
      MeetingQuestion.time,
      MeetingQuestion.visibility,
      MeetingQuestion.guests,
      MeetingQuestion.access,
      MeetingQuestion.title,
    ],
    initialOption: MeetingQuestion.title,
    labelBuilder: (question) => meetingQuestionNames[question]!,
  );
  final private = knobs.boolean(
    label: '비공개',
    description: '비공개면 게스트 대신 참여할 사람(넣은 이메일 수)이 보인다',
  );
  final excluded = knobs.boolean(label: '제외한 날 있음', initialValue: true);
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: MeetingAnswerSummary(
      flow: meetingFlowAt(current, private: private, excluded: excluded),
      onEdit: (_) {},
    ),
  );
}
