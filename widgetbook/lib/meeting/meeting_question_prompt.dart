import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_question_prompt.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_c.dart';

typedef _Prompt = ({String? lead, String headline, String? guide});

/// 모임 만들기에서 묻는 질문들
const _prompts = <String, _Prompt>{
  '기간': (lead: null, headline: meetingRangeQuestion, guide: meetingRangeGuide),
  '제외할 날짜': (
    lead: null,
    headline: meetingExclusionQuestion,
    guide: meetingExclusionGuide,
  ),
  '받는 방식': (lead: null, headline: meetingModeQuestion, guide: null),
  '시간 범위': (
    lead: null,
    headline: meetingHoursQuestion,
    guide: meetingHoursGuide,
  ),
  '공개 여부': (
    lead: meetingVisibilityExplain,
    headline: meetingVisibilityQuestion,
    guide: null,
  ),
  '게스트': (
    lead: null,
    headline: meetingGuestQuestion,
    guide: meetingGuestExplain,
  ),
  '참여할 사람': (
    lead: null,
    headline: meetingAccessQuestion,
    guide: meetingAccessGuide,
  ),
  '제목': (lead: null, headline: meetingTitleQuestion, guide: meetingTitleGuide),
};

@widgetbook.UseCase(
  name: '모임 만들기 질문 글',
  type: MeetingQuestionPrompt,
  path: '[모임]/모임 만들기',
)
Widget meetingQuestionPrompt(BuildContext context) {
  final knobs = context.knobs;
  final which = knobs.object.dropdown(
    label: '질문',
    options: _prompts.keys.toList(),
    initialOption: '공개 여부',
  );
  final answered = knobs.boolean(
    label: '답한 질문',
    description: '기간을 고른 뒤 제외할 날짜를 묻는 동안 위에 남은 기간 질문처럼 글자를 흐리게 한다',
  );
  final prompt = _prompts[which]!;
  return meetingCreateFrame(
    MeetingQuestionPrompt(
      lead: prompt.lead,
      headline: prompt.headline,
      guide: answered && which == '기간'
          ? meetingRangeAnswer(
              MeetingDates.range(DateTime(2027, 3, 2), DateTime(2027, 3, 6)),
            )
          : prompt.guide,
      answered: answered,
    ),
  );
}
