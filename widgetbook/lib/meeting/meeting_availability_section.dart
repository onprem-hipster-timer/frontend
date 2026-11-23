import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';

@widgetbook.UseCase(
  name: '내 시간 선택하기',
  type: MeetingAvailabilitySection,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingAvailabilitySection(BuildContext context) {
  final knobs = context.knobs;
  final mode = gridModeKnob(
    context,
    description: '모임을 만들 때 고른 방식. 시간별은 날짜마다 시각 띠, 날짜별은 달력, 요일별은 월~일 일곱 칸이다',
  );
  final viewer = gridViewerKnob(
    context,
    description:
        '로그인 전에는 붓 대신 로그인 안내가 뜨고 칸 색은 사람 수만 보인다. 아직 참여 전이면 칠하는 순간 참여한다',
  );
  final answers = gridAnswersKnob(
    context,
    description: '다른 사람이 되는 칸일수록 진하다. 아무도 없으면 내가 칠한 칸만 보인다',
  );
  final mine = knobs.boolean(
    label: '내 시간 칠해 둠',
    description: '주인·참여자·게스트일 때 이미 칠해 둔 내 칸. 끄면 처음 들어온 것처럼 비어 있다',
    initialValue: true,
  );
  final meeting = gridMeeting(mode);
  final visitor = viewer == GridViewer.visitor;
  // 시간별 날짜 머리로 하루를 지우면 되돌리기 알림이 뜨므로 앱의 모임 화면처럼 Scaffold 안에 둔다
  return Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GridHost(
        key: ValueKey((mode, viewer, answers, mine)),
        board: gridBoard(meeting, viewer: viewer, answers: answers, mine: mine),
        builder: (context, host) => MeetingAvailabilitySection(
          meeting: meeting,
          shading: gridShading(host.board, viewer),
          onPaint: visitor ? null : host.paint,
          onLocked: visitor ? () {} : null,
          highlight: host.highlight,
        ),
      ),
    ),
  );
}
