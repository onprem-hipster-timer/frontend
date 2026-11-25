import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_kept_guest_notice_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: '게스트로 계속하기 안내',
  type: MeetingKeptGuestNoticeView,
  path: '[모임]/들어오기·계정',
)
Widget meetingKeptGuestNoticeView(BuildContext context) {
  final busy = context.knobs.boolean(
    label: '게스트로 돌아가는 중',
    description: "누른 뒤 끝날 때까지 '게스트로 계속하기'를 누를 수 없다",
  );
  // 앱에서는 게스트로 시간을 넣다가 정규 유저로 바꾸려고 로그인을 그만둔 방문자의 모임 화면에서 시간표 바로 위에
  // 놓인다. 카탈로그에서는 눌러도 아무 데도 가지 않는다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: MeetingKeptGuestNoticeView(busy: busy, onContinue: () {}),
  );
}
