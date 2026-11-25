import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_answer_buttons.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_stagger.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_step_switcher.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_c.dart';

typedef _Question = ({
  String? lead,
  String headline,
  String? guide,
  List<String> answers,
});

/// 답 버튼으로 넘어가는 모임 만들기 질문들. 마지막 다음은 처음으로 돌아간다
const _questions = <_Question>[
  (
    lead: null,
    headline: meetingHoursQuestion,
    guide: meetingHoursGuide,
    answers: [meetingYes, meetingNo],
  ),
  (
    lead: meetingVisibilityExplain,
    headline: meetingVisibilityQuestion,
    guide: null,
    answers: [meetingPublic, meetingPrivate],
  ),
  (
    lead: null,
    headline: meetingGuestQuestion,
    guide: meetingGuestExplain,
    answers: [meetingAllowGuests, meetingRefuseGuests],
  ),
];

@widgetbook.UseCase(
  name: '질문 넘어가기',
  type: MeetingStepSwitcher,
  path: '[모임]/화면 틀',
)
Widget meetingStepSwitcher(BuildContext context) {
  final reduce = context.knobs.boolean(
    label: '애니메이션 줄이기',
    description: meetingReduceMotionDescription,
  );
  return meetingMotionSetting(
    context,
    reduce: reduce,
    child: meetingCreateFrame(const _Questions()),
  );
}

/// 답을 누르면 다음 질문으로 넘어간다
class _Questions extends StatefulWidget {
  const _Questions();

  @override
  State<_Questions> createState() => _QuestionsState();
}

class _QuestionsState extends State<_Questions> {
  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final question = _questions[_step % _questions.length];
    return MeetingStepSwitcher(
      step: _step,
      announcement: question.headline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeetingQuestionPrompt(
            lead: question.lead,
            headline: question.headline,
            guide: question.guide,
          ),
          const SizedBox(height: 20),
          MeetingStagger(
            order: 2,
            child: MeetingAnswerButtons(
              answers: [
                for (final label in question.answers)
                  (label: label, onPressed: () => setState(() => _step++)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
