import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_guest_import_phase.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_account_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_action.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_finish_slot_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_import_notice_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_member_body_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_participants_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'samples_grid.dart';
import 'samples_meeting_a.dart';

/// 화면 폭 노브의 선택지. null은 미리보기 기기 폭 그대로다
const _widths = <String, double?>{'기기 폭 그대로': null, '1024 (넓은 배치)': 1024};

/// '저장하기' 자리 노브의 선택지
const _phases = {
  '바꾸기 전': null,
  '자동 저장 중': MeetingFinishPhase.autosaving,
  '자동 저장됨': MeetingFinishPhase.autosaved,
  '입력을 마침': MeetingFinishPhase.done,
  '저장 실패': MeetingFinishPhase.failed,
};

/// '게스트 시간 옮기기' 노브의 선택지
const _imports = {
  '없음': null,
  '옮기는 중': MeetingGuestImportPhase.importing,
  '옮기지 못함': MeetingGuestImportPhase.failed,
};

/// 보는 사람마다 지금 계정 줄의 말
const _accounts = {
  GridViewer.owner: 'momo@example.com 계정으로 진행 중입니다',
  GridViewer.member: 'tokki@example.com 계정으로 진행 중입니다',
  GridViewer.guest: '게스트 곰돌이로 진행 중입니다',
  GridViewer.newcomer: 'saessak@example.com 계정으로 진행 중입니다',
};

@widgetbook.UseCase(
  name: '로그인한 뒤 모임 화면',
  type: MeetingMemberBodyView,
  path: '[모임]/모임 화면',
)
Widget meetingMemberBodyView(BuildContext context) {
  final knobs = context.knobs;
  final width = knobs.object.dropdown(
    label: '화면 폭',
    description:
        '840부터 격자 오른쪽에 계정·링크·일정 참여자·추천 시간을 상자로 둔다. 좁으면 계정은 격자 앞의 작은 한 줄이고 '
        '격자 → 추천 시간 → 일정 참여자 → 링크 순서다',
    options: _widths.keys.toList(),
  );
  final viewer = gridViewerKnob(
    context,
    viewers: const [
      GridViewer.owner,
      GridViewer.member,
      GridViewer.guest,
      GridViewer.newcomer,
    ],
    description:
        "게스트는 게스트 이름과 '안전한 정규 유저로 바꾸기'가 보이고, 카드에 '내 달력에 넣기'가 없다. "
        "주인만 '수정하기'를 누를 수 있다",
  );
  final mode = gridModeKnob(context, description: '모임을 만들 때 고른 방식');
  final answers = gridAnswersKnob(
    context,
    description: '다른 사람이 되는 칸일수록 진하고, 두 명 이상 함께 되는 칸이 추천 시간에 오른다',
  );
  final longNames = knobs.boolean(label: '긴 이름');
  final phase = knobs.object.dropdown(
    label: '저장하기',
    description: '내 시간을 바꾸기 전에는 없고, 바꾸면 저절로 저장하는 상태와 저장하기가 보인다. 좁으면 화면 아래에 붙는다',
    options: _phases.keys.toList(),
  );
  final import = knobs.object.dropdown(
    label: '게스트 시간 옮기기',
    description: '게스트로 시간을 넣다가 로그인한 회원이면 격자 바로 위에서 그 시간을 계정으로 옮긴다',
    options: _imports.keys.toList(),
  );
  final meeting = gridMeeting(mode);
  final guest = viewer == GridViewer.guest;
  final importPhase = _imports[import];
  // 칠하면 칸이 바뀌고, 추천 시간 카드에 마우스를 올리거나 누르면 격자의 그 칸을 강조한다
  return Scaffold(
    body: MeetingWidthFrame(
      width: _widths[width],
      child: _Body(
        key: ValueKey((mode, viewer, answers, longNames)),
        board: gridBoard(
          meeting,
          viewer: viewer,
          answers: answers,
          longNames: longNames,
        ),
        builder: (context, host, slotsKey) => MeetingMemberBodyView(
          board: host.board,
          highlight: host.highlight,
          slotsKey: slotsKey,
          link: Uri.parse('https://momeet.example.com/meetings/sample-meeting'),
          onPaint: host.paint,
          onAddToCalendar: guest ? null : (_) {},
          account: MeetingAccountPanel(
            text: _accounts[viewer]!,
            guest: guest,
            onSignOut: () {},
            onUpgrade: guest ? () {} : null,
          ),
          linkPanel: MeetingLinkPanelView(
            meetingId: meeting.id,
            owner: viewer == GridViewer.owner,
            level: VisibilityLevel.public,
            onShare: () {},
          ),
          participants: MeetingParticipantsPanel(
            board: host.board,
            onRename: () {},
            onRemove: host.remove,
          ),
          notice: guest || importPhase == null
              ? null
              : MeetingGuestImportNoticeView(
                  phase: importPhase,
                  onRetry: () {},
                ),
          action: (pinned) => MeetingFinishSlotView(
            phase: _phases[phase],
            pinned: pinned,
            onPressed: () {},
            onSaveKey: () {},
          ),
        ),
      ),
    ),
  );
}

/// 칠하기·빼기에 반응하는 모임 화면 값([GridHost])과 추천 시간에 다는 키를 쥔다
class _Body extends StatefulWidget {
  const _Body({super.key, required this.board, required this.builder});

  final MeetingBoard board;
  final Widget Function(
    BuildContext context,
    GridHostState host,
    GlobalKey slotsKey,
  )
  builder;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _slotsKey = GlobalKey();

  @override
  Widget build(BuildContext context) => GridHost(
    board: widget.board,
    builder: (context, host) => widget.builder(context, host, _slotsKey),
  );
}
