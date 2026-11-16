import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_crown.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 참여자 이름 칩. 주인은 왕관, 회원은 옅은 색에 사람 아이콘, 게스트는 회색에 빈 사람 아이콘, 나는 강조색 테두리다
class MeetingNameChip extends StatelessWidget {
  const MeetingNameChip({
    super.key,
    required this.name,
    this.owner = false,
    this.guest = false,
    this.self = false,
    this.dense = false,
  });

  final String name;
  final bool owner;
  final bool guest;
  final bool self;

  /// 카드 안처럼 좁은 곳의 작은 칩
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = self
        ? (scheme.primaryContainer, scheme.onPrimaryContainer)
        : guest
        ? (scheme.surfaceContainerHighest, scheme.onSurfaceVariant)
        : (scheme.secondaryContainer, scheme.onSecondaryContainer);
    final iconSize = dense ? 14.0 : 16.0;
    final style =
        (dense ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
            ?.copyWith(color: foreground);
    return Semantics(
      container: true,
      label: [
        name,
        if (owner) '주인',
        if (guest) '게스트',
        if (self) '나',
      ].join(', '),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 3 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          border: self ? Border.all(color: scheme.primary) : null,
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (owner)
              MeetingCrown(size: iconSize)
            else
              Icon(
                guest ? Icons.person_outline : Icons.person,
                size: iconSize,
                color: foreground,
              ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (self) ...[
              const SizedBox(width: 4),
              Text('나', style: style?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}
