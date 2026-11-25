import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_row_view.dart';

/// 모임 공유 링크 글과 복사 버튼. 복사하면 알린다
class MeetingLinkRow extends ConsumerWidget {
  const MeetingLinkRow({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MeetingLinkRowView(
      link: meetingLink(context, ref, meetingId),
      onCopy: () => copyMeetingLink(context, ref, meetingId),
    );
  }
}
