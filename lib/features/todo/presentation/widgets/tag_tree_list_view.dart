import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/todo/presentation/providers/tag_providers.dart';

/// 태그 트리 리스트 뷰
///
/// 태그 그룹을 ExpansionTile로 표시하고,
/// 태그는 드래그앤드롭으로 그룹 간 이동이 가능합니다.
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
          return const Center(
            child: Text('태그 그룹이 없습니다'),
          );
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
    final groupColor = _parseColor(group.color);

    return DragTarget<TagDragData>(
      onAcceptWithDetails: (details) async {
        final dragData = details.data;
        if (dragData.groupId != group.id) {
          // 다른 그룹으로 태그 이동
          try {
            await ref.read(tagMutationsProvider.notifier).updateTag(
                  dragData.tagId,
                  TagUpdate(
                    // groupId는 TagUpdate에 없으므로 다른 방법 사용 필요
                    name: null, // 이름은 변경하지 않음
                  ),
                );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('태그 이동 기능이 곧 구현됩니다'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            }
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('태그 이동 실패: ${error.toString()}'),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isReceivingDrag = candidateData.isNotEmpty;

        return Card(
          elevation: isReceivingDrag ? 4 : 1,
          color: isReceivingDrag ? groupColor.withValues(alpha: 0.1) : null,
          child: ExpansionTile(
            key: PageStorageKey('tag_group_${group.id}'),
            initiallyExpanded: isExpanded,
            onExpansionChanged: onExpansionChanged,
            leading: CircleAvatar(
              backgroundColor: groupColor,
              radius: 12,
              child: Text(
                group.tags.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (group.isTodoGroup)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TODO',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
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
                ...group.tags.map((tag) => DraggableTagTile(
                      tag: tag,
                      groupColor: groupColor,
                    )),

              // 태그 추가 버튼
              ListTile(
                leading: Icon(
                  Icons.add,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  '태그 추가',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => _showCreateTagDialog(context, ref, group.id),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 색상 문자열을 Color로 파싱
  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// 태그 생성 다이얼로그 표시
  void _showCreateTagDialog(
      BuildContext context, WidgetRef ref, String groupId) {
    // TODO: 태그 생성 다이얼로그 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('태그 생성 다이얼로그가 곧 구현됩니다')),
    );
  }
}

/// 드래그 가능한 태그 타일
class DraggableTagTile extends StatelessWidget {
  final TagRead tag;
  final Color groupColor;

  const DraggableTagTile({
    super.key,
    required this.tag,
    required this.groupColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tagColor = _parseColor(tag.color);

    return LongPressDraggable<TagDragData>(
      data: TagDragData(
        tagId: tag.id,
        tagName: tag.name,
        groupId: tag.groupId,
      ),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tagColor, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tag.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            tag.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          subtitle: tag.description != null
              ? Text(
                  tag.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                )
              : null,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
            ),
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
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  // TODO: 태그 수정 다이얼로그
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('태그 수정 기능이 곧 구현됩니다')),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmDialog(context, tag);
                  break;
              }
            },
          ),
        ),
      ),
    );
  }

  /// 색상 문자열을 Color로 파싱
  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(BuildContext context, TagRead tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('태그 "${tag.name}"을(를) 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 삭제 로직 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('태그 삭제 기능이 곧 구현됩니다')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

/// 태그 드래그 데이터 클래스
class TagDragData {
  final String tagId;
  final String tagName;
  final String groupId;

  const TagDragData({
    required this.tagId,
    required this.tagName,
    required this.groupId,
  });
}
