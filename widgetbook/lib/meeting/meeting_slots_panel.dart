import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';

@widgetbook.UseCase(name: '추천 시간', type: MeetingSlotsPanel, path: '[모임]/추천 시간')
Widget meetingSlotsPanel(BuildContext context) {
  final knobs = context.knobs;
  final mode = gridModeKnob(
    context,
    description: '카드 글과 정렬 이름(날짜 순·요일 순, 시간 긴 순·기간 긴 순)이 방식에 따라 바뀐다',
  );
  final viewer = gridViewerKnob(
    context,
    viewers: const [GridViewer.member, GridViewer.guest],
    description: '게스트는 달력이 없어 카드에 \'내 달력에 넣기\'가 없다',
  );
  final answers = gridAnswersKnob(
    context,
    description: '두 명 이상 함께 되는 칸이 없으면 추천 대신 안내 한 줄이 보인다',
  );
  final pinned = knobs.boolean(
    label: '첫 카드 고정',
    description: '카드를 누르면 고정되어 이름을 카드 안에 펼치고, 격자의 그 칸을 강조한다',
  );
  final longNames = knobs.boolean(label: '긴 이름');
  final side = knobs.boolean(
    label: '넓은 화면 옆 칸',
    description: '840 이상에서는 격자 오른쪽 칸의 남은 높이를 채우고 카드 목록만 상자 안에서 굴린다',
  );
  final meeting = gridMeeting(mode);
  final panel = GridHost(
    key: ValueKey((mode, viewer, answers, pinned, longNames)),
    board: gridBoard(
      meeting,
      viewer: viewer,
      answers: answers,
      longNames: longNames,
    ),
    pinFirst: pinned,
    builder: (context, host) => MeetingSlotsPanel(
      board: host.board,
      fill: side,
      highlight: host.highlight,
      link: Uri.parse('https://momeet.example.com/meetings/sample-meeting'),
      onAddToCalendar: viewer == GridViewer.guest ? null : (_) {},
    ),
  );
  // '복사'·'모두 복사'가 알림을 띄우므로 앱의 모임 화면처럼 Scaffold 안에 둔다
  return Scaffold(
    body: side
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 328, height: 520, child: panel),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: panel,
          ),
  );
}
