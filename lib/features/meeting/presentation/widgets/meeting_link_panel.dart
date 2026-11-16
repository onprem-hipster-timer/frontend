import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/shared/ui/ui.dart';

/// '링크': 모임 공유 링크와 복사 버튼
class MeetingLinkPanel extends ConsumerWidget {
  const MeetingLinkPanel({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return MeetingPanel(
      title: '링크',
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppRadius.mdAll,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  '${meetingLink(context, ref, meetingId)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: '링크 복사',
            icon: const Icon(Icons.copy),
            onPressed: () => copyMeetingLink(context, ref, meetingId),
          ),
        ],
      ),
    );
  }
}
