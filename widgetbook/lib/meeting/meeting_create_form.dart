import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_create_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_edit_actions.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_title_field.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_meeting_a.dart';

@widgetbook.UseCase(
  name: '모임 전체 설정 폼',
  type: MeetingCreateForm,
  path: '[모임]/모임 만들기',
)
Widget meetingCreateForm(BuildContext context) {
  final knobs = context.knobs;
  final edit = knobs.boolean(
    label: '모임 설정 화면',
    description: '만든 모임을 고칠 때도 같은 폼이다. 제목 칸 자리에 저장하기, 맨 아래에 모임 삭제가 온다',
  );
  final private = knobs.boolean(
    label: '비공개',
    description: '비공개면 공개 여부 아래에 참여할 사람(이메일·도메인)을 넣는 칸이 온다',
  );
  final asked = knobs.boolean(
    label: '참여할 사람 안 정하고 누름',
    description: '비공개인데 이메일을 넣지 않고 만들기(저장하기)를 누른 뒤',
  );
  final refused = knobs.boolean(
    label: '서버가 날짜를 거절함',
    description: '모임 설정 화면에서 저장했는데 서버가 날짜를 받지 않았을 때 달력 아래에 알린다',
  );
  final width = knobs.object.dropdown(
    label: '화면 폭',
    description: '720부터 카드 안에 담고 날짜를 왼쪽, 나머지 설정을 오른쪽에 둔다',
    options: meetingWidthOptions.keys.toList(),
  );
  // '전체 설정 펼치기'로 펼친 흐름. 비공개는 이메일을 넣지 않은 채로 둔다
  var initial = meetingFlowAt(MeetingQuestion.title).expand();
  if (private) initial = initial.withDraft(initial.draft.withPublic(false));
  return MeetingWidthFrame(
    width: meetingWidthOptions[width],
    child: MeetingFlowHost(
      key: ValueKey((private, edit)),
      initial: initial,
      builder: (context, flow, onChanged, title) => MeetingCreateForm(
        flow: flow,
        today: meetingSampleToday,
        accessAsked: asked,
        accessRequiredText: edit
            ? meetingEditAccessRequired
            : meetingFormAccessRequired,
        timezone: 'Asia/Seoul',
        refusals: {
          if (edit && refused)
            MeetingEditPart.dates: meetingEditRefusalText(
              MeetingEditPart.dates,
            ),
        },
        titleField: edit
            ? MeetingEditActions(
                controller: title,
                placeholder: '모모님의 모임 일정',
                notices: const [],
                saving: false,
                onSave: () {},
              )
            : MeetingTitleField(
                controller: title,
                placeholder: '모모님의 모임 일정',
                submitting: false,
                onSubmit: () {},
              ),
        footer: edit
            ? TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text(meetingDelete),
              )
            : null,
        onChanged: onChanged,
      ),
    ),
  );
}
