import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_access_question.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

@widgetbook.UseCase(
  name: '참여할 사람 질문',
  type: MeetingAccessQuestion,
  path: '[모임]/모임 만들기',
)
Widget meetingAccessQuestion(BuildContext context) {
  final filled = context.knobs.boolean(
    label: '이메일 넣음',
    description: "하나도 넣지 않으면 '다 넣었어요'를 누를 수 없다",
  );
  var initial = meetingFlowAt(MeetingQuestion.access);
  if (filled) {
    initial = initial
        .addAccessEntry((value: 'momo@example.com', domain: false))
        .addAccessEntry((value: 'example.org', domain: true));
  }
  // 공개 여부에 '비공개'로 답하면 나오는 질문. 답하면 제목 질문으로 넘어가므로 처음 모양으로 되돌려 보인다
  return MeetingFlowHost(
    key: ValueKey(filled),
    initial: initial,
    builder: (context, flow, onChanged, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MeetingAccessQuestion(
        flow: flow.current == MeetingQuestion.access ? flow : initial,
        onChanged: onChanged,
      ),
    ),
  );
}
