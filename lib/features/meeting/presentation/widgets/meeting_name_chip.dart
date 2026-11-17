import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_crown.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 참여자 이름 칩. 주인은 왕관, 회원은 옅은 색에 사람 아이콘, 게스트는 회색에 빈 사람 아이콘, 나는 강조색 테두리다.
///
/// [onRemove]나 [onRename]을 주면 이름 뒤에 빼기·이름 바꾸기 단추를 둔다(일정 참여자의 편집).
class MeetingNameChip extends StatelessWidget {
  const MeetingNameChip({
    super.key,
    required this.name,
    this.owner = false,
    this.guest = false,
    this.self = false,
    this.dense = false,
    this.onRemove,
    this.onRename,
  });

  final String name;
  final bool owner;
  final bool guest;
  final bool self;

  /// 카드 안처럼 좁은 곳의 작은 칩
  final bool dense;

  final VoidCallback? onRemove;
  final VoidCallback? onRename;

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
    final onRemove = this.onRemove;
    final onRename = this.onRename;
    final action = onRemove != null
        ? (Icons.close, '$name 빼기', onRemove)
        : onRename != null
        ? (Icons.edit_outlined, '내 닉네임 바꾸기', onRename)
        : null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        dense ? 8 : 10,
        dense ? 3 : 6,
        action == null ? (dense ? 8 : 10) : 2,
        dense ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        border: self ? Border.all(color: scheme.primary) : null,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _Label(
              name: name,
              owner: owner,
              guest: guest,
              self: self,
              iconSize: iconSize,
              color: foreground,
              style: style,
            ),
          ),
          if (action case (final icon, final tooltip, final onPressed))
            IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              icon: Icon(icon, size: 16, color: foreground),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

/// 칩의 아이콘(왕관·회원·게스트), 이름, '나'. 스크린 리더는 이름 뒤에 주인·게스트·나를 읽는다
class _Label extends StatelessWidget {
  const _Label({
    required this.name,
    required this.owner,
    required this.guest,
    required this.self,
    required this.iconSize,
    required this.color,
    required this.style,
  });

  final String name;
  final bool owner;
  final bool guest;
  final bool self;
  final double iconSize;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: [
        name,
        if (owner) '주인',
        if (guest) '게스트',
        if (self) '나',
      ].join(', '),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (owner)
            MeetingCrown(size: iconSize)
          else
            Icon(
              guest ? Icons.person_outline : Icons.person,
              size: iconSize,
              color: color,
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
    );
  }
}
