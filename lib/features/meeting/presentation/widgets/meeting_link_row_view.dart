import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 공유 링크 글과 복사 버튼
class MeetingLinkRowView extends StatelessWidget {
  const MeetingLinkRowView({
    super.key,
    required this.link,
    required this.onCopy,
  });

  /// 모임 공유 링크
  final Uri link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.mdAll,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text('$link', style: theme.textTheme.bodyMedium),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: '링크 복사',
          icon: const Icon(Icons.copy),
          onPressed: onCopy,
        ),
      ],
    );
  }
}
