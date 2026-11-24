import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_choice_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '로그인·Guest 고르기',
  type: MeetingLoginChoiceView,
  path: '[모임]/들어오기·계정',
)
Widget meetingLoginChoiceView(BuildContext context) {
  final guests = context.knobs.boolean(
    label: '게스트 받기',
    initialValue: true,
    description: "게스트를 받는 모임이면 '로그인' 옆에 'Guest'와 그 안내를 둔다",
  );
  // 앱에서는 넓은 화면 오른쪽 칸(380 폭)의 '로그인' 상자와 좁은 화면의 요청 시트 안에 놓인다.
  // 카탈로그에서는 눌러도 아무 데도 가지 않는다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: MeetingPanel(
          title: '로그인',
          child: MeetingLoginChoiceView(
            onLogin: () {},
            onGuest: guests ? () {} : null,
          ),
        ),
      ),
    ),
  );
}
