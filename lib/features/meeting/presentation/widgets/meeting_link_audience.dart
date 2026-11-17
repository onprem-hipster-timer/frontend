import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_create_texts.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 비공개 모임의 링크를 누가 열 수 있는지 알리는 조용한 한 줄. 공개나 알 수 없는 범위([level])면 그리지 않는다
class MeetingLinkAudience extends StatelessWidget {
  const MeetingLinkAudience({super.key, required this.level});

  final VisibilityLevel? level;

  @override
  Widget build(BuildContext context) {
    final text = meetingLinkAudienceText(level);
    if (text == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          level == VisibilityLevel.private
              ? Icons.lock_outline
              : Icons.alternate_email,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
