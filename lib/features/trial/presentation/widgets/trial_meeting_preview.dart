import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/meeting.dart'
    show
        MeetingAccountPanel,
        MeetingBoard,
        MeetingGlassBar,
        MeetingLinkPanelView,
        MeetingMemberBodyView,
        MeetingPageTitle,
        MeetingParticipantsPanel,
        MeetingRunHighlight,
        MeetingRunOrder,
        meetingRunKey;
import 'package:momeet/features/trial/presentation/utils/trial_texts.dart';
import 'package:momeet/features/trial/presentation/widgets/trial_inert.dart';

/// 그림 속 모임 화면의 폭(휴대폰)
const _pageWidth = 360.0;

/// 모임 화면 한 장의 그림. [board]의 모임을 로그인한 주인([email] 계정)이 휴대폰에서 보는 모임 화면을 앱의
/// 위젯 그대로 그린다: 제목과 모임 설정 연필이 있는 머리띠, 계정 줄, 칠한 시간 격자, 추천 시간, 일정 참여자, 링크.
/// 첫 추천 시간은 누른 채로 두어 격자의 그 칸을 강조하고 함께 되는 사람의 이름을 펼친다.
///
/// 화면은 폭 360으로 그리고 받은 칸의 폭에 맞게 줄인다. 높이는 칸의 비율대로라 칸이 낮으면 화면의 위쪽만
/// 보인다. 글자 배율은 따르지 않는다. 조용한 둥근 테두리 안에 두고, 무엇도 반응하지 않으며([TrialInert])
/// 스크린 리더에는 그림 전체를 한 줄([trialMeetingPreviewLabel])로 읽힌다.
///
/// 테스트: test/features/trial/presentation/widgets/trial_meeting_preview_test.dart
class TrialMeetingPreview extends StatefulWidget {
  const TrialMeetingPreview({
    super.key,
    required this.board,
    required this.email,
  });

  final MeetingBoard board;
  final String email;

  @override
  State<TrialMeetingPreview> createState() => _TrialMeetingPreviewState();
}

class _TrialMeetingPreviewState extends State<TrialMeetingPreview> {
  final _highlight = MeetingRunHighlight();
  final _slotsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 첫 추천 시간을 누른 채로 두어 격자의 그 칸과 함께 되는 사람의 이름을 보인다
    final runs = widget.board.runs(MeetingRunOrder.recommended);
    if (runs.isNotEmpty) _highlight.toggle(meetingRunKey(runs.first));
  }

  @override
  void dispose() {
    _highlight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final page = _Page(
      board: widget.board,
      email: widget.email,
      highlight: _highlight,
      slotsKey: _slotsKey,
    );
    return Semantics(
      container: true,
      image: true,
      label: trialMeetingPreviewLabel,
      child: ExcludeSemantics(
        child: TrialInert(
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = constraints.maxWidth / _pageWidth;
                  final size = Size(_pageWidth, constraints.maxHeight / scale);
                  return FittedBox(
                    alignment: Alignment.topCenter,
                    child: SizedBox.fromSize(
                      size: size,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: size,
                          padding: EdgeInsets.zero,
                          viewPadding: EdgeInsets.zero,
                          viewInsets: EdgeInsets.zero,
                          textScaler: TextScaler.noScaling,
                        ),
                        child: page,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 주인이 휴대폰에서 보는 모임 화면: 유리 머리띠와 로그인한 사람의 본문
class _Page extends StatelessWidget {
  const _Page({
    required this.board,
    required this.email,
    required this.highlight,
    required this.slotsKey,
  });

  final MeetingBoard board;
  final String email;
  final MeetingRunHighlight highlight;
  final GlobalKey slotsKey;

  @override
  Widget build(BuildContext context) {
    final meeting = board.meeting;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: MeetingGlassBar(
        title: MeetingPageTitle(meeting.title, onEdit: () {}),
        back: false,
        under: false,
      ),
      body: MeetingMemberBodyView(
        board: board,
        highlight: highlight,
        slotsKey: slotsKey,
        link: Uri(path: '/meetings/${meeting.id}'),
        onPaint: (_) {},
        onAddToCalendar: (_) {},
        account: MeetingAccountPanel(
          text: '$email 계정으로 진행 중입니다',
          onSignOut: () {},
        ),
        linkPanel: MeetingLinkPanelView(
          meetingId: meeting.id,
          owner: board.ownedByMe,
          level: meeting.visibilityLevel,
          onShare: () {},
        ),
        participants: MeetingParticipantsPanel(
          board: board,
          onRename: () {},
          onRemove: (_) {},
        ),
        notice: null,
        // 칠한 것을 바꾸기 전의 '저장하기' 자리는 비어 있다
        action: (_) => const SizedBox.shrink(),
      ),
    );
  }
}
