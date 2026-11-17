import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_answer_buttons.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_hours_question.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_mode_question.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';

/// 날짜(기간·제외) 밖의 지금 질문: 받는 방식, 시간, 공개 여부, 게스트, 제목. 다시 묻는 질문이면 지금 답을
/// 채워 보인다
class MeetingCurrentQuestion extends StatelessWidget {
  const MeetingCurrentQuestion({
    super.key,
    required this.flow,
    required this.timezone,
    required this.titleField,
    required this.onChanged,
  });

  final MeetingFlow flow;

  /// 아직 모르면 null
  final String? timezone;

  /// 제목 칸과 만들기 화살표
  final Widget titleField;

  final ValueChanged<MeetingFlow> onChanged;

  @override
  Widget build(BuildContext context) {
    final flow = this.flow;
    final draft = flow.draft;
    final editing = flow.editing;
    return switch (flow.current) {
      MeetingQuestion.mode => MeetingModeQuestion(
        hourlyAvailable: draft.hourlyAvailable,
        chosen: editing == MeetingQuestion.mode ? draft.mode : null,
        onChoose: (mode) => onChanged(flow.chooseMode(mode)),
      ),
      MeetingQuestion.time => MeetingHoursQuestion(
        flow: flow,
        timezone: timezone,
        onChanged: onChanged,
      ),
      MeetingQuestion.visibility => _ChoiceQuestion(
        lead: meetingVisibilityExplain,
        headline: meetingVisibilityQuestion,
        selected: editing == MeetingQuestion.visibility
            ? (draft.isPublic ? meetingPublic : meetingPrivate)
            : null,
        answers: [
          (
            label: meetingPublic,
            onPressed: () => onChanged(flow.choosePublic(true)),
          ),
          (
            label: meetingPrivate,
            onPressed: () => onChanged(flow.choosePublic(false)),
          ),
        ],
      ),
      MeetingQuestion.guests => _ChoiceQuestion(
        headline: meetingGuestQuestion,
        guide: meetingGuestExplain,
        selected: editing == MeetingQuestion.guests
            ? (draft.allowGuests ? meetingAllowGuests : meetingRefuseGuests)
            : null,
        answers: [
          (
            label: meetingAllowGuests,
            onPressed: () => onChanged(flow.chooseGuests(true)),
          ),
          (
            label: meetingRefuseGuests,
            onPressed: () => onChanged(flow.chooseGuests(false)),
          ),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MeetingQuestionPrompt(
            headline: meetingTitleQuestion,
            guide: meetingTitleGuide,
          ),
          const SizedBox(height: 16),
          titleField,
        ],
      ),
    };
  }
}

/// 둘 중 하나를 고르는 질문(공개 여부, 게스트)
class _ChoiceQuestion extends StatelessWidget {
  const _ChoiceQuestion({
    required this.headline,
    required this.answers,
    this.lead,
    this.guide,
    this.selected,
  });

  final String headline;
  final String? lead;
  final String? guide;
  final List<MeetingAnswer> answers;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MeetingQuestionPrompt(lead: lead, headline: headline, guide: guide),
        const SizedBox(height: 20),
        MeetingAnswerButtons(answers: answers, selected: selected),
      ],
    );
  }
}
