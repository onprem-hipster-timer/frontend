import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';
import 'package:momeet/core/utils/color_utils.dart';

/// 태그 트리 리스트 뷰
///
/// 태그 그룹을 ExpansionTile로 표시합니다.
class TagTreeListView extends ConsumerWidget {
  const TagTreeListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagGroupsAsync = ref.watch(tagGroupsProvider);
    final expansionState = ref.watch(tagTreeExpansionProvider);

    return tagGroupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '태그를 불러올 수 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(tagGroupsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (tagGroups) {
        if (tagGroups.isEmpty) {
          return const Center(child: Text('태그 그룹이 없습니다'));
        }

        return ListView.builder(
          itemCount: tagGroups.length,
          itemBuilder: (context, index) {
            final group = tagGroups[index];
            final isExpanded = expansionState[group.id] ?? false;

            return TagGroupExpansionTile(
              group: group,
              isExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                ref
                    .read(tagTreeExpansionProvider.notifier)
                    .setGroupExpanded(group.id, expanded);
              },
            );
          },
        );
      },
    );
  }
}

/// 태그 그룹을 표시하는 ExpansionTile
class TagGroupExpansionTile extends ConsumerWidget {
  final TagGroupReadWithTags group;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const TagGroupExpansionTile({
    super.key,
    required this.group,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupColor = HexColor.fromHex(group.color);

    return Card(
      elevation: 1,
      child: ExpansionTile(
        key: PageStorageKey('tag_group_${group.id}'),
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        leading: CircleAvatar(
          backgroundColor: groupColor,
          radius: 12,
          child: Text(
            group.tags.length.toString(),
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          group.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: group.description != null
            ? Text(
                group.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        children: [
          if (group.tags.isEmpty)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('태그가 없습니다'),
              subtitle: Text('새 태그를 추가해보세요'),
            )
          else
            ...group.tags.map(
              (tag) => TagTile(tag: tag, groupColor: groupColor),
            ),

          // 태그 추가 버튼
          ListTile(
            leading: Icon(Icons.add, color: theme.colorScheme.primary),
            title: Text(
              '태그 추가',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => _showCreateTagDialog(context, group.id),
          ),
        ],
      ),
    );
  }

  /// 태그 생성 다이얼로그 표시
  void _showCreateTagDialog(BuildContext context, String groupId) {
    showTagFormSheet(context, defaultGroupId: groupId);
  }
}

/// 태그 타일
class TagTile extends ConsumerWidget {
  final TagRead tag;
  final Color groupColor;

  const TagTile({super.key, required this.tag, required this.groupColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagColor = HexColor.fromHex(tag.color);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle),
        ),
        title: Text(
          tag.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: tag.description != null
            ? Text(
                tag.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('수정'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('삭제', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                showTagFormSheet(context, tag: tag);
                break;
              case 'delete':
                await _showDeleteConfirmDialog(context, ref, tag);
                break;
            }
          },
        ),
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    TagRead tag,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '태그 삭제',
      content: '태그 "${tag.name}"을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(tagMutationsProvider.notifier).deleteTag(tag.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tag.name} 태그가 삭제되었습니다'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('태그 삭제에 실패했습니다: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
