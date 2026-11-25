import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_account_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_audience.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';

@widgetbook.UseCase(name: '모임 화면 배치', type: MeetingLayout, path: '[모임]/화면 틀')
Widget meetingLayout(BuildContext context) {
  final knobs = context.knobs;
  final width = knobs.double.slider(
    label: '화면 폭',
    description: '840부터 격자 오른쪽에 상자를 두는 두 칸 배치가 된다. 카탈로그 화면보다 넓으면 줄여서 보인다',
    initialValue: 360,
    min: 320,
    max: 1440,
    divisions: 28,
    precision: 0,
  );
  final action = knobs.boolean(
    label: '저장하기',
    description: '내 시간을 칠한 뒤에 생긴다. 좁으면 화면 아래 띠, 넓으면 격자 아래 오른쪽',
    initialValue: true,
  );
  final account = MeetingAccountPanel(
    text: 'momo@example.com 계정으로 진행 중입니다',
    onSignOut: () {},
  );
  final link = MeetingPanel(
    title: '링크',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {},
                child: const Text('공유하기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('수정하기'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const MeetingLinkAudience(level: VisibilityLevel.allowedEmails),
      ],
    ),
  );
  final meeting = gridMeeting(MeetingMode.hourly);
  // 앱의 모임 화면(로그인한 주인 모모)처럼 격자·추천 시간·일정 참여자가 한 값을 나눠 쓴다. 칠하면 추천 시간도 바뀐다
  final layout = GridHost(
    board: gridBoard(meeting, viewer: GridViewer.owner),
    builder: (context, host) {
      Widget slots({bool fill = false}) => MeetingSlotsPanel(
        board: host.board,
        fill: fill,
        highlight: host.highlight,
        link: Uri.parse('https://momeet.example.com/meetings/sample-meeting'),
        onAddToCalendar: (_) {},
      );
      final participants = MeetingParticipantsPanel(
        board: host.board,
        onRename: () {},
        onRemove: host.remove,
      );
      return MeetingLayout(
        main: MeetingAvailabilitySection(
          meeting: meeting,
          shading: host.board,
          onPaint: host.paint,
          highlight: host.highlight,
        ),
        side: [account, link, participants],
        sideFill: slots(fill: true),
        header: account,
        secondary: [slots()],
        tertiary: [participants, link],
        action: action
            ? (pinned) => MeetingFinishAction(
                phase: MeetingFinishPhase.autosaved,
                pinned: pinned,
                onPressed: () {},
              )
            : null,
      );
    },
  );
  // 앱의 모임 화면처럼 Scaffold 안에 두어 복사·하루 지우기 알림이 뜬다
  return Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        if (width <= constraints.maxWidth) {
          return Center(
            child: SizedBox(width: width, child: layout),
          );
        }
        // 화면보다 넓은 폭은 같은 비율로 줄여 한눈에 보인다
        final scale = constraints.maxWidth / width;
        return FittedBox(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight / scale,
            child: layout,
          ),
        );
      },
    ),
  );
}
