import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel_view.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _levels = {
  '공개': VisibilityLevel.public,
  '정한 이메일만': VisibilityLevel.allowedEmails,
  '나만': VisibilityLevel.private,
};

@widgetbook.UseCase(
  name: '링크',
  type: MeetingLinkPanelView,
  path: '[모임]/들어오기·계정',
)
Widget meetingLinkPanelView(BuildContext context) {
  final knobs = context.knobs;
  final owner = knobs.boolean(
    label: '주인',
    description:
        "모임을 만든 사람만 '수정하기'를 누를 수 있다. 다른 사람에게는 막혀 있고 만든 사람만 고칠 수 있다고 알린다",
  );
  final level = knobs.object.dropdown(
    label: '공개 범위',
    options: _levels.keys.toList(),
    description: '비공개 모임이면 버튼 아래에 누가 열 수 있는지 한 줄로 알린다',
  );
  // 앱에서는 넓은 화면 오른쪽 칸(380 폭)과 좁은 화면 아래쪽에 놓인다. '공유하기'는 시스템 공유 창을
  // 여는데, 카탈로그에서는 아무것도 열지 않는다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: MeetingLinkPanelView(
          meetingId: 'meeting-1',
          owner: owner,
          level: _levels[level],
          onShare: () {},
        ),
      ),
    ),
  );
}
