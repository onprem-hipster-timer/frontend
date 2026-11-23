import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/mypage/presentation/widgets/meeting_entry_section.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '모임 만들기 항목',
  type: MeetingEntrySection,
  path: '[마이페이지]',
)
Widget meetingEntrySection(BuildContext context) {
  // 앱에서는 '내 모임' 카드의 맨 위 줄이다. 누르면 모임 만들기 화면으로 가는데 카탈로그에는 화면 이동이 없다
  return const SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: Card(clipBehavior: Clip.antiAlias, child: MeetingEntrySection()),
  );
}
