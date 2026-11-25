import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_exclusion_question.dart';
import 'package:momeet_widgetbook/meeting/samples_meeting_b.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

final _ranges = {
  '주말 낀 열흘 (3월 2일 ~ 3월 11일)': (
    DateTime.utc(2027, 3, 2),
    DateTime.utc(2027, 3, 11),
  ),
  '평일 나흘 (3월 2일 ~ 3월 5일)': (DateTime.utc(2027, 3, 2), DateTime.utc(2027, 3, 5)),
};

final _excluded = {
  '없음': <DateTime>[],
  '하루': [DateTime.utc(2027, 3, 4)],
  '여러 날': [
    DateTime.utc(2027, 3, 3),
    DateTime.utc(2027, 3, 4),
    DateTime.utc(2027, 3, 8),
    DateTime.utc(2027, 3, 9),
    DateTime.utc(2027, 3, 10),
  ],
};

@widgetbook.UseCase(
  name: '제외할 날짜 질문',
  type: MeetingExclusionQuestion,
  path: '[모임]/모임 만들기',
)
Widget meetingExclusionQuestion(BuildContext context) {
  final knobs = context.knobs;
  final range = knobs.object.dropdown(
    label: '고른 기간',
    description: "뺄 수 있는 주말이 기간 안에 있을 때만 '주말 제외'가 보인다",
    options: _ranges.keys.toList(),
  );
  final excluded = knobs.object.dropdown(
    label: '달력에서 뺀 날',
    description: "뺀 날이 없으면 '없어요', 있으면 뺀 날을 적고 '다 골랐어요'로 답한다",
    options: _excluded.keys.toList(),
  );
  final (start, end) = _ranges[range]!;
  final flow = MeetingFlow(
    draft: MeetingDraft(
      dates: MeetingDates.range(start, end, excluded: _excluded[excluded]!),
    ),
    answered: const {MeetingQuestion.range},
  );
  // 앱에서는 이 질문 위에 달력이 있다. 달력은 따로 볼 수 있다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: MeetingSampleHolder<MeetingFlow>(
      key: ValueKey((range, excluded)),
      initial: flow,
      builder: (flow, onChanged) =>
          MeetingExclusionQuestion(flow: flow, onChanged: onChanged),
    ),
  );
}
