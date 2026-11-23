import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_questions.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

@widgetbook.UseCase(
  name: '모임 만들기 질문 화면',
  type: MeetingCreateQuestions,
  path: '[모임]/모임 만들기',
)
Widget meetingCreateQuestions(BuildContext context) {
  final knobs = context.knobs;
  final question = knobs.object.dropdown(
    label: '시작 질문',
    description: '앞 질문은 예시 답(3월 8일~12일, 시간별, 공개)으로 채운다. 답을 누르면 다음 질문으로 넘어간다',
    options: MeetingQuestion.values,
    labelBuilder: (question) => meetingQuestionNames[question]!,
  );
  final private = knobs.boolean(
    label: '비공개',
    description: "공개 여부에 '비공개'로 답한 흐름(게스트 대신 참여할 사람을 묻는다)",
  );
  final width = knobs.object.dropdown(
    label: '화면 폭',
    description: '720부터 넓은 배치: 카드 안에 담고, 날짜를 묻는 동안은 달력이 오른쪽으로 간다',
    options: meetingWidthOptions.keys.toList(),
  );
  // 앱에서는 모임 만들기 화면의 유리 머리띠 아래 본문 전체다
  return MeetingWidthFrame(
    width: meetingWidthOptions[width],
    child: MeetingFlowHost(
      key: ValueKey((question, private)),
      initial: meetingFlowAt(question, private: private),
      builder: (context, flow, onChanged, title) => MeetingCreateQuestions(
        flow: flow,
        today: meetingSampleToday,
        timezone: 'Asia/Seoul',
        titleField: MeetingTitleField(
          controller: title,
          placeholder: '모모님의 모임 일정',
          submitting: false,
          onSubmit: () {},
        ),
        onChanged: onChanged,
        onExpand: () {},
      ),
    ),
  );
}
