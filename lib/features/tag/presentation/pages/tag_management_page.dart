import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/tag/domain/tag_group_with_tags.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/widgets/confirm_dialog.dart';

/// 태그 관리 페이지
///
/// CustomScrollView + SliverList를 사용하여 계층형 태그 구조를 효율적으로 렌더링합니다.
/// 태그 그룹과 하위 태그들을 ExpansionTile로 표시하고, 생성/수정/삭제 기능을 제공합니다.
class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagTreeAsync = ref.watch(tagTreeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('태그 관리'),
        elevation: 0,
        centerTitle: true,
      ),
      body: tagTreeAsync.when(
        data: (tagGroups) => _buildTagList(context, ref, tagGroups),
        loading: () => _buildLoadingView(),
        error: (error, stack) => _buildErrorView(context, ref, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('새 그룹'),
        tooltip: '새 태그 그룹 만들기',
      ),
    );
  }

  /// 태그 리스트 위젯 (CustomScrollView + SliverList)
  Widget _buildTagList(
    BuildContext context,
    WidgetRef ref,
    List<TagGroupWithTags> tagGroups,
  ) {
    if (tagGroups.isEmpty) {
      return _buildEmptyView(context);
    }

    return CustomScrollView(
      slivers: [
        // 각 태그 그룹을 SliverList로 렌더링
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildTagGroupItem(context, ref, tagGroups[index], tagGroups),
            childCount: tagGroups.length,
          ),
        ),

        // 하단 여백 (FloatingActionButton 공간 확보)
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 80),
        ),
      ],
    );
  }

  /// 개별 태그 그룹 아이템
  Widget _buildTagGroupItem(
    BuildContext context,
    WidgetRef ref,
    TagGroupWithTags tagGroup,
    List<TagGroupWithTags> allGroups,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),

          // 그룹 헤더 - 좌측에 색상 점과 그룹 이름
          leading: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: HexColor.fromHex(tagGroup.groupColor),
              shape: BoxShape.circle,
            ),
          ),

          title: Row(
            children: [
              Expanded(
                child: Text(
                  tagGroup.groupName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Todo 그룹 배지
              if (tagGroup.isTodoGroup) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TODO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 그룹 설명
              Text(
                tagGroup.groupDescription ?? '${tagGroup.tagCount}개의 태그',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),

              // 그룹 액션 버튼들
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 태그 추가 버튼 (주요 액션)
                  FilledButton.icon(
                    onPressed: () =>
                        _showCreateTagSheet(context, ref, tagGroup, allGroups),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('태그 추가'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),

                  // 그룹 수정 버튼
                  OutlinedButton.icon(
                    onPressed: () => _showEditGroupSheet(context, tagGroup),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('그룹 수정'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),

                  // 그룹 삭제 버튼
                  OutlinedButton.icon(
                    onPressed: () => _showDeleteGroupDialog(context, ref, tagGroup),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('그룹 삭제'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 하위 태그 목록
          children: tagGroup.tags
              .map((tag) =>
                  _buildTagItem(context, ref, tag, tagGroup, allGroups))
              .toList(),
        ),
      ),
    );
  }

  /// 개별 태그 아이템 (ListTile)
  Widget _buildTagItem(
    BuildContext context,
    WidgetRef ref,
    TagRead tag,
    TagGroupWithTags parentGroup,
    List<TagGroupWithTags> allGroups,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // 좌측: 태그 색상의 원(Dot)
        leading: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: HexColor.fromHex(tag.color),
            shape: BoxShape.circle,
          ),
        ),

        // 중앙: 태그 이름
        title: Text(
          tag.name,
          style: theme.textTheme.bodyLarge,
        ),

        subtitle:
            tag.description?.isNotEmpty == true ? Text(tag.description!) : null,

        // 우측: 액션 버튼들
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 태그 수정 버튼
            OutlinedButton.icon(
              onPressed: () =>
                  _showEditTagSheet(context, ref, tag, parentGroup, allGroups),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('수정'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),

            const SizedBox(width: 8),

            // 태그 삭제 버튼
            OutlinedButton.icon(
              onPressed: () => _showDeleteTagDialog(context, ref, tag),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('삭제'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),

        // Interaction: 탭하면 수정 폼
        onTap: () =>
            _showEditTagSheet(context, ref, tag, parentGroup, allGroups),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: theme.colorScheme.surface,
        hoverColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      ),
    );
  }

  /// 로딩 뷰
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('태그를 불러오는 중...'),
        ],
      ),
    );
  }

  /// 에러 뷰
  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '태그를 불러올 수 없습니다',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(tagTreeProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 빈 상태 뷰
  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '아직 태그가 없습니다',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '태그 그룹을 만들어 태그를 정리해보세요',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateGroupSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('첫 태그 그룹 만들기'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Event Handlers
  // ============================================================

  /// 새 태그 그룹 생성 시트 표시
  void _showCreateGroupSheet(BuildContext context) {
    showTagGroupFormSheet(context);
  }

  /// 태그 그룹 수정 시트 표시
  void _showEditGroupSheet(
    BuildContext context,
    TagGroupWithTags tagGroup,
  ) {
    // TagGroupReadWithTags를 생성하여 전달
    final groupWithTags = TagGroupReadWithTags(
      id: tagGroup.groupId,
      name: tagGroup.groupName,
      color: tagGroup.groupColor,
      isTodoGroup: tagGroup.isTodoGroup,
      createdAt: tagGroup.createdAt,
      updatedAt: tagGroup.updatedAt,
      description: tagGroup.groupDescription,
      tags: tagGroup.tags,
    );

    showTagGroupFormSheet(context, tagGroup: groupWithTags);
  }

  /// 태그 그룹 삭제 확인 다이얼로그
  Future<void> _showDeleteGroupDialog(
    BuildContext context,
    WidgetRef ref,
    TagGroupWithTags tagGroup,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '그룹 삭제',
      content: '${tagGroup.groupName} 그룹을 삭제하시겠습니까?\n'
          '이 작업은 되돌릴 수 없습니다.\n'
          '그룹에 포함된 모든 태그도 함께 삭제됩니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(tagMutationsProvider.notifier).deleteGroup(tagGroup.groupId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tagGroup.groupName} 그룹이 삭제되었습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('그룹 삭제에 실패했습니다: $error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 새 태그 생성 시트 표시
  void _showCreateTagSheet(
    BuildContext context,
    WidgetRef ref,
    TagGroupWithTags parentGroup,
    List<TagGroupWithTags> allGroups,
  ) {
    final tagGroupsAsync = ref.read(tagTreeProvider);

    tagGroupsAsync.when(
      data: (allGroups) {
        showTagFormSheet(
          context,
          availableGroups: allGroups,
          defaultGroupId: parentGroup.groupId,
        );
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  /// 태그 수정 시트 표시
  void _showEditTagSheet(
    BuildContext context,
    WidgetRef ref,
    TagRead tag,
    TagGroupWithTags parentGroup,
    List<TagGroupWithTags> allGroups,
  ) {
    final tagGroupsAsync = ref.read(tagTreeProvider);

    tagGroupsAsync.when(
      data: (allGroups) {
        showTagFormSheet(
          context,
          tag: tag,
          availableGroups: allGroups,
        );
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  /// 태그 삭제 확인 다이얼로그
  Future<void> _showDeleteTagDialog(
    BuildContext context,
    WidgetRef ref,
    TagRead tag,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '태그 삭제',
      content: '${tag.name} 태그를 삭제하시겠습니까?\n'
          '이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
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
}
