import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_audience.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _levels = {
  '정한 이메일만': VisibilityLevel.allowedEmails,
  '나만': VisibilityLevel.private,
  '공개': VisibilityLevel.public,
};

@widgetbook.UseCase(
  name: '링크를 열 수 있는 사람 안내',
  type: MeetingLinkAudience,
  path: '[모임]/들어오기·계정',
)
Widget meetingLinkAudience(BuildContext context) {
  final level = context.knobs.object.dropdown(
    label: '공개 범위',
    description: "'링크' 상자와 모임을 만든 뒤 화면의 링크 아래에 뜬다. 공개 모임이면 아무것도 보이지 않는다",
    options: _levels.keys.toList(),
  );
  return Padding(
    padding: const EdgeInsets.all(16),
    child: MeetingLinkAudience(level: _levels[level]),
  );
}
