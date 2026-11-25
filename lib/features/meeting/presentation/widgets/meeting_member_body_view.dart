import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/domain/meeting_board.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_run_highlight.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_grid_geometry.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_slots_panel.dart';

/// 로그인한 회원·게스트의 모임 화면 본문: 지금 계정([account]), 내 시간 격자, 링크([linkPanel]), 일정 참여자
/// ([participants]), 추천 시간.
///
/// 넓으면 격자 오른쪽에 계정 → 링크 → 일정 참여자 → 추천 시간을 상자로 둔다(추천 시간은 남은 높이를 채우고 그
/// 안에서 굴린다). 좁으면 계정은 격자 앞의 조용한 한 줄이고, 격자 → 추천 시간 → 일정 참여자 → 링크 순서로 뒤로
/// 갈수록 덜 눈에 띈다. [notice]가 있으면 격자 바로 위에 둔다. [action]은 '저장하기' 자리다.
///
/// [onAddToCalendar]가 없으면(게스트) 카드에 '내 달력에 넣기'가 없다. 추천 시간 카드에 마우스를 올리거나
/// 누르면 격자의 그 칸을 강조한다([highlight]).
class MeetingMemberBodyView extends StatelessWidget {
  const MeetingMemberBodyView({
    super.key,
    required this.board,
    required this.highlight,
    required this.slotsKey,
    required this.link,
    required this.onPaint,
    required this.onAddToCalendar,
    required this.account,
    required this.linkPanel,
    required this.participants,
    required this.notice,
    required this.action,
  });

  final MeetingBoard board;
  final MeetingRunHighlight highlight;

  /// 추천 시간에 다는 키('저장하기'가 마친 뒤 보이게 굴린다)
  final GlobalKey slotsKey;

  /// 추천 시간을 복사할 때 붙이는 모임 링크
  final Uri link;
  final MeetingPaint onPaint;
  final ValueChanged<MeetingRun>? onAddToCalendar;

  /// 지금 계정
  final Widget account;

  /// '링크' 상자
  final Widget linkPanel;

  /// '일정 참여자'
  final Widget participants;

  /// 격자 바로 위의 안내. 없으면 격자만 둔다
  final Widget? notice;

  /// '저장하기' 자리. 좁으면 화면 아래에 붙는다(`pinned`)
  final Widget Function(bool pinned) action;

  @override
  Widget build(BuildContext context) {
    final availability = MeetingAvailabilitySection(
      meeting: board.meeting,
      shading: board,
      onPaint: onPaint,
      highlight: highlight,
    );
    // 넓으면 오른쪽 칸, 좁으면 격자 아래에 하나만 그린다
    Widget slots({bool fill = false}) => KeyedSubtree(
      key: slotsKey,
      child: MeetingSlotsPanel(
        board: board,
        fill: fill,
        highlight: highlight,
        link: link,
        onAddToCalendar: onAddToCalendar,
      ),
    );
    final notice = this.notice;
    return MeetingLayout(
      main: notice == null
          ? availability
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [notice, availability],
            ),
      side: [account, linkPanel, participants],
      sideFill: slots(fill: true),
      header: account,
      secondary: [slots()],
      tertiary: [participants, linkPanel],
      action: action,
    );
  }
}
