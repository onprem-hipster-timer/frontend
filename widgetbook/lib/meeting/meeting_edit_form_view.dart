import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_edit.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_edit_providers.dart'
    show MeetingEditOutcome;
import 'package:momeet/features/meeting/presentation/utils/meeting_edit_texts.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_edit_form_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';
import 'samples_meeting_a.dart';

/// 저장 상태 노브의 선택지
enum _Phase {
  idle('고치는 중'),
  saving('저장하는 중'),
  partlySaved('일부만 저장함'),
  refused('서버가 날짜를 거절함'),
  deleting('삭제하는 중');

  const _Phase(this.label);

  final String label;
}

@widgetbook.UseCase(
  name: '모임 설정',
  type: MeetingEditFormView,
  path: '[모임]/모임 설정',
)
Widget meetingEditFormView(BuildContext context) {
  final knobs = context.knobs;
  final phase = knobs.object.dropdown(
    label: '저장 상태',
    description:
        '저장하기는 바꾼 것만 보낸다. 하나라도 저장하지 못하면 무엇을 저장했고 못 했는지 알리고, 서버가 거절한 칸은 그 아래에 알린다',
    options: _Phase.values,
    labelBuilder: (phase) => phase.label,
  );
  final private = knobs.boolean(
    label: '비공개(정한 이메일만)',
    description: '비공개 모임이면 넣어 둔 이메일·도메인을 채운다',
  );
  final hasAnswers = knobs.boolean(
    label: '참여자가 답을 넣음',
    description: '답이 있으면 받는 방식을 바꾸거나 날을 뺄 때 저장하기 위에 한 줄씩 알린다',
  );
  final asked = knobs.boolean(
    label: '참여할 사람 안 정하고 누름',
    description: '비공개로 바꾸고 이메일을 넣지 않은 채 저장하기를 누른 뒤',
  );
  final width = knobs.object.dropdown(
    label: '화면 폭',
    description: '720부터 카드 안에 담고 날짜를 왼쪽, 나머지 설정을 오른쪽에 둔다',
    options: meetingWidthOptions.keys.toList(),
  );
  final base = MeetingEditBase(
    meeting: gridMeeting(MeetingMode.hourly),
    audience: private
        ? const MeetingAudience(
            VisibilityLevel.allowedEmails,
            emails: ['momo@example.com', 'tokki@example.com'],
            domains: ['example.org'],
          )
        : const MeetingAudience(VisibilityLevel.public),
  );
  // 앱에서는 저장하지 못한 까닭(네트워크, 서버 거절 등)을 끝에 붙인다
  final outcome = switch (phase) {
    _Phase.partlySaved => meetingEditOutcomeText(
      MeetingEditOutcome(
        base: base,
        saved: const {MeetingEditPart.title},
        unsaved: const {MeetingEditPart.dates},
      ),
    ),
    _Phase.refused => '저장하지 못했어요. 표시한 칸을 확인해 주세요',
    _ => null,
  };
  return MeetingWidthFrame(
    width: meetingWidthOptions[width],
    child: MeetingEditFormView(
      key: ValueKey(private),
      base: base,
      hasAnswers: hasAnswers,
      today: meetingSampleToday,
      placeholder: '모모님의 모임 일정',
      saving: phase == _Phase.saving,
      deleting: phase == _Phase.deleting,
      accessAsked: asked,
      refusals: {
        if (phase == _Phase.refused)
          MeetingEditPart.dates: meetingEditRefusalText(MeetingEditPart.dates),
      },
      outcome: outcome,
      onEdited: () {},
      onSave: (_, _) {},
      onDelete: () {},
    ),
  );
}
