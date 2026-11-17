import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_audience.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_row.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// '링크': 모임 공유 링크와 복사 버튼. 비공개 모임([level])이면 그 아래에 누가 열 수 있는지 한 줄로 알린다
class MeetingLinkPanel extends StatelessWidget {
  const MeetingLinkPanel({super.key, required this.meetingId, this.level});

  final String meetingId;

  /// 모임의 공개 범위. 모르면 null(알리지 않는다)
  final VisibilityLevel? level;

  @override
  Widget build(BuildContext context) {
    return MeetingPanel(
      title: '링크',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeetingLinkRow(meetingId: meetingId),
          if (level != null && level != VisibilityLevel.public) ...[
            const SizedBox(height: 8),
            MeetingLinkAudience(level: level),
          ],
        ],
      ),
    );
  }
}
