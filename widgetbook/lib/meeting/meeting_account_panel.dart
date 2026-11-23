import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_account_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_quiet_panels.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '지금 계정',
  type: MeetingAccountPanel,
  path: '[모임]/들어오기·계정',
)
Widget meetingAccountPanel(BuildContext context) {
  final knobs = context.knobs;
  final guest = knobs.boolean(
    label: '게스트',
    description: "게스트는 이름으로 보이고 '안전한 정규 유저로 바꾸기'가 붙는다",
  );
  final long = knobs.boolean(label: '긴 이메일·이름');
  final wide = knobs.boolean(
    label: '넓은 화면',
    description: '넓으면 오른쪽 칸의 로그인 상자, 좁으면 모임 화면 맨 위의 상자 없는 작은 한 줄',
  );
  final text = guest
      ? '게스트 ${long ? '이름이 아주 길어서 줄을 넘기는 다람쥐' : '다람쥐'}로 진행 중입니다'
      : '${long ? 'momo.weekly.meetup.organizer@example.com' : 'momo@example.com'}'
            ' 계정으로 진행 중입니다';
  final panel = MeetingAccountPanel(
    text: text,
    guest: guest,
    onSignOut: () {},
    onUpgrade: guest ? () {} : null,
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    // 넓은 화면의 오른쪽 칸은 380 폭이다
    child: wide
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: panel,
            ),
          )
        : MeetingQuietPanels(child: panel),
  );
}
