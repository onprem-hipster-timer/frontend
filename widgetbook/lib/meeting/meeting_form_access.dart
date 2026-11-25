import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_form_access.dart';
import 'package:momeet_widgetbook/meeting/samples_meeting_b.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '참여할 사람',
  type: MeetingFormAccess,
  path: '[모임]/모임 만들기',
)
Widget meetingFormAccess(BuildContext context) {
  final knobs = context.knobs;
  final filled = knobs.boolean(label: '넣은 이메일·도메인 있음', initialValue: true);
  final onlyMe = knobs.boolean(
    label: '지금은 나만 볼게요',
    description: '고르면 이메일 칸이 막힌다',
  );
  final asked = knobs.boolean(
    label: '빈 채로 만들기를 누름',
    description: '이메일도 없고 나만 보기도 고르지 않은 채 화살표(모임 설정이면 저장하기)를 누르면 아래에 알린다',
  );
  var draft = const MeetingDraft(isPublic: false, allowGuests: false);
  if (filled) {
    draft = draft
        .withAccessEntry((value: 'momo@example.com', domain: false))
        .withAccessEntry((value: 'tokki@example.com', domain: false))
        .withAccessEntry((value: 'example.org', domain: true));
  }
  draft = draft.withOnlyMe(onlyMe);
  // 펼친 폼에서 '공개 여부'를 끄면 그 아래에 열린다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: MeetingSampleHolder<MeetingDraft>(
      key: ValueKey((filled, onlyMe)),
      initial: draft,
      builder: (draft, onChanged) =>
          MeetingFormAccess(draft: draft, asked: asked, onChanged: onChanged),
    ),
  );
}
