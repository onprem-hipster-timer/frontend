import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';

/// 한 그룹의 태그 칩 줄과 그 그룹에 태그를 더하는 버튼
class TodoTagGroupRow extends StatelessWidget {
  const TodoTagGroupRow({
    super.key,
    required this.group,
    required this.selectedTagIds,
    required this.onToggle,
    required this.onAdd,
  });

  final TagGroupWithTags group;
  final Set<String> selectedTagIds;
  final void Function(String tagId, bool selected) onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: HexColor.fromHex(group.group.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.group.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('추가'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    textStyle: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tag in group.tags)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TagChip(
                      tag: tag,
                      selected: selectedTagIds.contains(tag.id),
                      onSelected: (value) => onToggle(tag.id, value),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _AddTagChip(onPressed: onAdd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onSelected,
  });

  final TagRead tag;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tagColor = HexColor.fromHex(tag.color);
    return FilterChip(
      label: Text(tag.name),
      selected: selected,
      onSelected: onSelected,
      selectedColor: tagColor.withValues(alpha: 0.2),
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
      checkmarkColor: tagColor,
      side: BorderSide(
        color: selected ? tagColor : colorScheme.outline.withValues(alpha: 0.3),
        width: selected ? 1.5 : 0.8,
      ),
      labelStyle: TextStyle(
        color: selected ? tagColor : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: Icon(Icons.add, size: 16, color: colorScheme.primary),
      label: Text(
        '태그 추가',
        style: TextStyle(color: colorScheme.primary, fontSize: 12),
      ),
      onPressed: onPressed,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      side: BorderSide(
        color: colorScheme.primary.withValues(alpha: 0.5),
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
