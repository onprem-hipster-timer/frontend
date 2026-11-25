import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_answer_buttons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// 모임 만들기 질문과 그 답
const _questions = {
  '시간 범위': [meetingYes, meetingNo],
  '공개 여부': [meetingPublic, meetingPrivate],
  '게스트': [meetingAllowGuests, meetingRefuseGuests],
};

@widgetbook.UseCase(
  name: '질문의 답 버튼',
  type: MeetingAnswerButtons,
  path: '[모임]/모임 만들기',
)
Widget meetingAnswerButtons(BuildContext context) {
  final knobs = context.knobs;
  final question = knobs.object.dropdown(
    label: '질문',
    options: _questions.keys.toList(),
  );
  final answered = knobs.boolean(
    label: '다시 묻는 질문',
    description: '이미 답한 질문을 다시 열면 지금 답을 채워 둔다',
  );
  final labels = _questions[question]!;
  return Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: MeetingAnswerButtons(
        answers: [for (final label in labels) (label: label, onPressed: () {})],
        selected: answered ? labels.first : null,
      ),
    ),
  );
}
