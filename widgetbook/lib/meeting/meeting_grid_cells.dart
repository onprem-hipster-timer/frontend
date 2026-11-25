import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_cells.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';

@widgetbook.UseCase(
  name: '격자 칸',
  type: MeetingGridCells,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingGridCells(BuildContext context) {
  final knobs = context.knobs;
  final mode = gridModeKnob(
    context,
    description: '시간별은 날짜마다 이어진 세로 띠, 날짜별·요일별은 떨어진 타일이다',
  );
  final viewer = gridViewerKnob(
    context,
    description: '로그인 전에는 칠할 수 없고 칸 색은 사람 수만 보인다',
  );
  final brush = knobs.object.dropdown(
    label: '붓',
    description: '마우스는 누른 채 끌면, 터치는 길게 누른 채 끌면 여러 칸을 칠한다',
    options: const [MeetingAnswer.available, MeetingAnswer.unavailable],
    labelBuilder: (answer) => answer == MeetingAnswer.available ? '가능' : '불가능',
  );
  final answers = gridAnswersKnob(context);
  final mine = knobs.boolean(label: '내 시간 칠해 둠', initialValue: true);
  final meeting = gridMeeting(mode);
  // 앱에서는 날짜·요일 머리와 시각 축 사이에 놓인다. 여기서는 칸 자리만 보인다
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: GridHost(
      key: ValueKey((mode, viewer, answers, mine)),
      board: gridBoard(meeting, viewer: viewer, answers: answers, mine: mine),
      builder: (context, host) => MeetingGridCells(
        shading: gridShading(host.board, viewer),
        shape: switch (mode) {
          MeetingMode.hourly => MeetingCellShape.hourly(
            slotMinutes: meeting.timeSlotMinutes,
            columnGap: 6,
          ),
          MeetingMode.weekly => MeetingCellShape.weekly,
          _ => MeetingCellShape.daily,
        },
        brush: brush,
        onPaint: viewer == GridViewer.visitor ? null : host.paint,
        onLocked: () {},
        highlight: host.highlight,
      ),
    ),
  );
}
