import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_group_row.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일 폼의 태그 고르기. 고른 태그를 위에 모아 보이고, 태그 그룹별로 태그 칩을 늘어놓는다.
/// 할 일에는 어느 태그 그룹의 태그든 붙일 수 있다.
class TodoTagPickerView extends StatelessWidget {
  const TodoTagPickerView({
    super.key,
    required this.tagGroups,
    required this.selectedTagIds,
    required this.onToggle,
    required this.onCreateTag,
  });

  final AsyncValue<List<TagGroupWithTags>> tagGroups;
  final Set<String> selectedTagIds;
  final void Function(String tagId, bool selected) onToggle;

  /// 새 태그를 만든다. 태그 그룹 줄에서 누르면 그 그룹 id, 아니면 null
  final ValueChanged<String?> onCreateTag;

  @override
  Widget build(BuildContext context) {
    final content = tagGroups.when(
      data: (tagGroups) {
        final selectedTags = [
          for (final group in tagGroups)
            for (final tag in group.tags)
              if (selectedTagIds.contains(tag.id)) tag,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedTags.isNotEmpty) ...[
              _SelectedTags(
                tags: selectedTags,
                onRemove: (tag) => onToggle(tag.id, false),
              ),
              const SizedBox(height: 16),
            ],
            if (tagGroups.isEmpty)
              AppEmptyState(
                icon: Icons.label_outline,
                title: '아직 태그가 없습니다',
                message:
                    '${Terms.tagGroup.withJosa('을', '를')} 만든 뒤 그 안에 태그를 만들어 '
                    '${Terms.todo.withJosa('을', '를')} 분류해보세요',
                actionLabel: '첫 태그 만들기',
                onAction: () => onCreateTag(null),
              ),
            for (final group in tagGroups)
              if (group.tags.isNotEmpty)
                TodoTagGroupRow(
                  group: group,
                  selectedTagIds: selectedTagIds,
                  onToggle: onToggle,
                  onAdd: () => onCreateTag(group.group.id),
                ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => _LoadError(error: error),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TagHeader(onCreate: () => onCreateTag(null)),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}

/// '태그' 제목과 새 태그 버튼
class _TagHeader extends StatelessWidget {
  const _TagHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      '태그',
      trailing: TextButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('새 태그'),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }
}

/// 고른 태그들. x로 고르기를 푼다
class _SelectedTags extends StatelessWidget {
  const _SelectedTags({required this.tags, required this.onRemove});

  final List<TagRead> tags;
  final ValueChanged<TagRead> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택된 태그 (${tags.length})',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              Chip(
                label: Text(tag.name),
                backgroundColor: HexColor.fromHex(
                  tag.color,
                ).withValues(alpha: 0.2),
                side: BorderSide(color: HexColor.fromHex(tag.color), width: 1),
                deleteIcon: Icon(
                  Icons.close,
                  size: 16,
                  color: HexColor.fromHex(tag.color),
                ),
                onDeleted: () => onRemove(tag),
                labelStyle: TextStyle(
                  color: HexColor.fromHex(tag.color),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 태그를 불러오지 못했을 때의 안내
class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '태그를 불러오지 못했습니다: $error',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
