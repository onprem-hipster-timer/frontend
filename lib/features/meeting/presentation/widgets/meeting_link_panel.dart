import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel_view.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// '링크': '공유하기'([shareMeetingLink])와 '수정하기'(주인만 모임 설정을 연다. 다른 사람에게는 막혀 있고 만든
/// 사람만 고칠 수 있다고 알린다)를 같은 폭으로 나란히 둔다(큰 글자로 넘치면 위아래로 쌓는다). 비공개 모임([level])이면
/// 그 아래에 누가 열 수 있는지 한 줄로 알린다. 제목 줄 끝의 '나도 모임 만들기'(주인에게는 '새 모임 만들기')는
/// 모임 만들기 화면을 연다
class MeetingLinkPanel extends ConsumerWidget {
  const MeetingLinkPanel({
    super.key,
    required this.meetingId,
    required this.title,
    this.owner = false,
    this.level,
  });

  final String meetingId;

  /// 공유 창에 넣는 모임 제목
  final String title;

  /// 로그인한 사람이 주인인지
  final bool owner;

  /// 모임의 공개 범위. 모르면 null(알리지 않는다)
  final VisibilityLevel? level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MeetingLinkPanelView(
      meetingId: meetingId,
      owner: owner,
      level: level,
      onShare: () =>
          shareMeetingLink(context, ref, meetingId: meetingId, title: title),
    );
  }
}
