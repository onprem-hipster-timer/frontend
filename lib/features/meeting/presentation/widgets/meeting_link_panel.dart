import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_row.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';

/// '링크': 모임 공유 링크와 복사 버튼
class MeetingLinkPanel extends StatelessWidget {
  const MeetingLinkPanel({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context) {
    return MeetingPanel(
      title: '링크',
      child: MeetingLinkRow(meetingId: meetingId),
    );
  }
}
