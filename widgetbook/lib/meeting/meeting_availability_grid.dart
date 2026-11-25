import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_grid.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';

@widgetbook.UseCase(
  name: '내 시간 격자',
  type: MeetingAvailabilityGrid,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingAvailabilityGrid(BuildContext context) {
  final knobs = context.knobs;
  final mode = gridModeKnob(
    context,
    description: '시간별은 날짜마다 시각 띠, 날짜별은 일요일부터의 달력, 요일별은 월~일 일곱 칸이다',
  );
  final viewer = gridViewerKnob(
    context,
    description: '로그인 전에는 칠할 수 없고 칸 색은 사람 수만 보인다',
  );
  final brush = knobs.object.dropdown(
    label: '붓',
    description: '격자 위 붓 고르기에서 고른 답. 이미 그 답인 칸에서 끌기 시작하면 지운다',
    options: const [MeetingAnswer.available, MeetingAnswer.unavailable],
    labelBuilder: (answer) => answer == MeetingAnswer.available ? '가능' : '불가능',
  );
  final answers = gridAnswersKnob(context);
  final mine = knobs.boolean(label: '내 시간 칠해 둠', initialValue: true);
  final pinned = knobs.boolean(
    label: '추천 시간 카드 고정',
    description: '추천 시간 카드를 누르거나 마우스를 올리면 격자의 그 칸을 테두리로 강조한다',
  );
  final meeting = gridMeeting(mode);
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: GridHost(
      key: ValueKey((mode, viewer, answers, mine, pinned)),
      board: gridBoard(meeting, viewer: viewer, answers: answers, mine: mine),
      pinFirst: pinned,
      builder: (context, host) => MeetingAvailabilityGrid(
        shading: gridShading(host.board, viewer),
        brush: brush,
        onPaint: viewer == GridViewer.visitor ? null : host.paint,
        onLocked: () {},
        highlight: host.highlight,
      ),
    ),
  );
}
