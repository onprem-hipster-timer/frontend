import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';

@widgetbook.UseCase(
  name: '일정 참여자',
  type: MeetingParticipantsPanel,
  path: '[모임]/참여자',
)
Widget meetingParticipantsPanel(BuildContext context) {
  final knobs = context.knobs;
  final viewer = gridViewerKnob(
    context,
    viewers: const [
      GridViewer.owner,
      GridViewer.member,
      GridViewer.guest,
      GridViewer.newcomer,
    ],
    initial: GridViewer.owner,
    description:
        '주인의 \'편집\'은 칩마다 빼기 단추를 두고 \'완료\'로 닫는다. 다른 사람의 \'편집\'은 내 닉네임 바꾸기를 열고, 아직 참여 전이면 없다',
  );
  final answers = gridAnswersKnob(context, description: '내 시간을 칠한 사람이 참여자가 된다');
  final longNames = knobs.boolean(label: '긴 이름');
  // 로그인 전에는 이 상자 대신 참여자 수만 보인다. 앱에서는 화면 폭의 상자로, 넓으면 격자 오른쪽 칸에 놓인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: GridHost(
      key: ValueKey((viewer, answers, longNames)),
      board: gridBoard(
        gridMeeting(MeetingMode.hourly),
        viewer: viewer,
        answers: answers,
        longNames: longNames,
      ),
      builder: (context, host) => MeetingParticipantsPanel(
        board: host.board,
        onRename: () {},
        onRemove: host.remove,
      ),
    ),
  );
}
