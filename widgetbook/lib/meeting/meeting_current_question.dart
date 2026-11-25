import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_current_question.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

const _questions = [
  MeetingQuestion.mode,
  MeetingQuestion.time,
  MeetingQuestion.visibility,
  MeetingQuestion.guests,
  MeetingQuestion.access,
  MeetingQuestion.title,
];

@widgetbook.UseCase(
  name: '지금 질문',
  type: MeetingCurrentQuestion,
  path: '[모임]/모임 만들기',
)
Widget meetingCurrentQuestion(BuildContext context) {
  final knobs = context.knobs;
  final question = knobs.object.dropdown(
    label: '질문',
    description: '날짜(기간·제외) 다음에 하나씩 묻는 질문. 답을 누르면 다음 질문으로 넘어간다',
    options: _questions,
    labelBuilder: (question) => meetingQuestionNames[question]!,
  );
  final editing = knobs.boolean(
    label: '요약을 눌러 다시 묻는 중',
    description: '이미 답한 질문을 다시 물으면 지금 답이 골라진 채로 보인다',
  );
  final timezone = knobs.boolean(
    label: '시간 기준 앎',
    initialValue: true,
    description: '시간 질문 아래의 시간 기준 한 줄. 기기 시간대를 읽기 전에는 비어 있다',
  );
  final initial = editing && question != MeetingQuestion.title
      ? meetingFlowAt(
          MeetingQuestion.title,
          private: question == MeetingQuestion.access,
        ).edit(question)
      : meetingFlowAt(question);
  return MeetingFlowHost(
    key: ValueKey((question, editing)),
    initial: initial,
    builder: (context, flow, onChanged, title) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MeetingCurrentQuestion(
        flow: flow,
        timezone: timezone ? 'Asia/Seoul' : null,
        titleField: MeetingTitleField(
          controller: title,
          placeholder: '모모님의 모임 일정',
          submitting: false,
          onSubmit: () {},
        ),
        onChanged: onChanged,
      ),
    ),
  );
}
