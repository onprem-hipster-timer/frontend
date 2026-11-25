import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_access_note.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '초대 메일 안내',
  type: MeetingAccessNote,
  path: '[모임]/모임 만들기',
)
Widget meetingAccessNote(BuildContext context) {
  // 앱에서는 비공개 모임의 '참여할 사람' 질문 안, 이메일 칸 위에 화면 폭으로 놓인다
  return const SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: MeetingAccessNote(),
  );
}
