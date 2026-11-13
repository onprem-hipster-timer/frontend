import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/tag_providers.dart' as tag_providers;
import 'package:momeet/shared/ui/ui.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form/todo_tag_group_row.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일 폼의 태그 고르기. 고른 태그를 위에 모아 보이고, 그룹별로 태그 칩을 늘어놓는다.
class TodoTagPicker extends ConsumerWidget {
  const TodoTagPicker({
    super.key,
    required this.lockedGroupId,
    required this.selectedTagIds,
    required this.onToggle,
    this.onFirstGroup,
  });

  /// 새 할 일이 들어갈 그룹. 주면 바꿀 수 없다는 표시와 함께 보인다
  final String? lockedGroupId;
  final Set<String> selectedTagIds;
  final void Function(String tagId, bool selected) onToggle;

  /// 태그 그룹을 불러온 뒤 첫 그룹 id로 한 번 불린다(새 할 일의 기본 그룹)
  final ValueChanged<String>? onFirstGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref
        .watch(tag_providers.tagTreeProvider)
        .when(
          data: (tagGroups) {
            final onFirstGroup = this.onFirstGroup;
            if (onFirstGroup != null && tagGroups.isNotEmpty) {
              final first = tagGroups.first.group.id;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => onFirstGroup(first),
              );
            }
            // 목록에 없는 그룹이면 보낼 때처럼 첫 그룹으로 본다
            final locked = lockedGroupId == null || tagGroups.isEmpty
                ? null
                : tagGroups
                          .where((g) => g.group.id == lockedGroupId)
                          .firstOrNull ??
                      tagGroups.first;
            final selectedTags = [
              for (final group in tagGroups)
                for (final tag in group.tags)
                  if (selectedTagIds.contains(tag.id)) tag,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (locked != null) ...[
                  _GroupBadge(group: locked.group),
                  const SizedBox(height: 12),
                ],
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
                        '새 태그를 만들어 ${Terms.todo.withJosa('을', '를')} 분류해보세요',
                    actionLabel: '첫 태그 만들기',
                    onAction: () => _createTag(context, ref),
                  ),
                for (final group in tagGroups)
                  if (group.tags.isNotEmpty)
                    TodoTagGroupRow(
                      group: group,
                      selectedTagIds: selectedTagIds,
                      onToggle: onToggle,
                      onAdd: () =>
                          _createTag(context, ref, groupId: group.group.id),
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
        _TagHeader(onCreate: () => _createTag(context, ref)),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}

/// 새 태그 만들기. [groupId]를 주면 그 그룹을 기본으로 고른다. 태그 그룹이 없으면 먼저 만들라고 알린다
Future<void> _createTag(
  BuildContext context,
  WidgetRef ref, {
  String? groupId,
}) async {
  final groups = ref
      .read(tag_providers.tagTreeProvider)
      .when(data: (g) => g, loading: () => const [], error: (_, _) => const []);
  if (groups.isEmpty) {
    showAppSnackBar(context, '먼저 태그 그룹을 생성해주세요. 태그 관리 페이지에서 그룹을 만들 수 있습니다.');
    return;
  }
  await showTagFormSheet(
    context,
    defaultGroupId: groupId ?? groups.first.group.id,
  );
  // 새로 만든 태그를 목록에 반영한다
  if (context.mounted) ref.invalidate(tag_providers.tagTreeProvider);
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

/// 새 할 일이 들어갈 그룹. 폼에서는 바꿀 수 없다
class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.group});

  final TagGroupRead group;

  @override
  Widget build(BuildContext context) {
    final groupColor = HexColor.fromHex(group.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: groupColor.withValues(alpha: 0.1),
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: groupColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_rounded, size: 16, color: groupColor),
          const SizedBox(width: 6),
          Text(
            '${group.name} 그룹',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: groupColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.lock_outline,
            size: 12,
            color: groupColor.withValues(alpha: 0.7),
          ),
        ],
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
