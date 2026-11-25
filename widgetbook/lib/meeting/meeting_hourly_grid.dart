import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_hourly_grid.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';

/// 하루 범위 노브의 선택지: 시작·끝 시각
const _ranges = {
  '9시 ~ 18시': ('09:00:00', '18:00:00'),
  '7시 ~ 22시': ('07:00:00', '22:00:00'),
  '0시 ~ 24시 (하루 전체)': ('00:00:00', '00:00:00'),
};

@widgetbook.UseCase(
  name: '시간별 격자',
  type: MeetingHourlyGrid,
  path: '[모임]/내 시간 선택하기',
)
Widget meetingHourlyGrid(BuildContext context) {
  final knobs = context.knobs;
  final range = knobs.object.dropdown(
    label: '하루 범위',
    description: '범위 밖의 시간은 칸 위아래에 \'받지 않는 시간\' 띠로 보인다. 하루 전체면 띠가 없다',
    options: _ranges.keys.toList(),
  );
  final days = knobs.int.slider(
    label: '기간 (일)',
    description: '날짜 열이 너무 좁아지면 왼쪽 시각은 둔 채 날짜와 칸을 옆으로 굴린다',
    initialValue: 5,
    min: 1,
    max: 14,
  );
  final viewer = gridViewerKnob(
    context,
    description: '로그인 전에는 칠할 수 없고, 칸이나 날짜 머리를 누르면 로그인하라고 알린다',
  );
  final brush = knobs.object.dropdown(
    label: '붓',
    description: '날짜 머리를 누르면 답하지 않은 날은 하루 전체를 가능으로 칠하고, 답한 날은 지운다',
    options: const [MeetingAnswer.available, MeetingAnswer.unavailable],
    labelBuilder: (answer) => answer == MeetingAnswer.available ? '가능' : '불가능',
  );
  final answers = gridAnswersKnob(context);
  final mine = knobs.boolean(label: '내 시간 칠해 둠', initialValue: true);
  final (start, end) = _ranges[range]!;
  final meeting = gridMeeting(
    MeetingMode.hourly,
    days: days,
    startTime: start,
    endTime: end,
  );
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: GridHost(
      key: ValueKey((range, days, viewer, answers, mine)),
      board: gridBoard(meeting, viewer: viewer, answers: answers, mine: mine),
      builder: (context, host) => MeetingHourlyGrid(
        shading: gridShading(host.board, viewer),
        brush: brush,
        onPaint: viewer == GridViewer.visitor ? null : host.paint,
        onLocked: () {},
        highlight: host.highlight,
      ),
    ),
  );
}
