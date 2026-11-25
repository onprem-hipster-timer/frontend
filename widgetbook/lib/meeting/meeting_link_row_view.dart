import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_row_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: '링크 줄', type: MeetingLinkRowView, path: '[모임]/모임 만들기')
Widget meetingLinkRowView(BuildContext context) {
  final link = context.knobs.string(
    label: '링크',
    description: '모임 화면 주소. 길면 줄을 넘긴다',
    initialValue:
        'https://momeet.example/meetings/3f2a9c1e-7b4d-4e8a-9c21-5d6f0a1b2c3d',
  );
  // 앱에서는 모임을 만든 뒤 화면의 폭 360 칸 가운데, QR 코드 아래에 놓인다. 복사하면 '링크를 복사했습니다'를
  // 알리는데, 카탈로그에서는 아무것도 복사하지 않는다
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: MeetingLinkRowView(link: Uri.parse(link), onCopy: () {}),
      ),
    ),
  );
}
