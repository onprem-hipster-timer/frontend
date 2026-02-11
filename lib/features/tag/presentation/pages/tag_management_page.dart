import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/features/tag/presentation/utils/color_utils.dart';

/// 태그 관리 페이지
///
/// 태그 그룹과 태그를 계층형 리스트로 보여주고,
/// 생성/수정/삭제 기능을 제공합니다.
class TagManagementPage extends ConsumerWidget {
  const TagManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagTreeAsync = ref.watch(tagTreeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('태그 관리'),
        elevation: 0,
        actions: [
          // 새 그룹 추가 버튼
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '새 태그 그룹',
            onPressed: () => _showCreateGroupDialog(context),
          ),
        ],
      ),
      body: tagTreeAsync.when(
        data: (tagGroups) => _buildTagList(context, ref, tagGroups),
        loading: () => _buildLoadingView(),
        error: (error, stack) => _buildErrorView(context, ref, error),
      ),
    );
  }

  /// 태그 리스트 위젯
  Widget _buildTagList(
    BuildContext context,
    WidgetRef ref,
    List<TagGroupReadWithTags> tagGroups,
  ) {
    if (tagGroups.isEmpty) {
      return _buildEmptyView(context);
    }

    return CustomScrollView(
      slivers: [
        // 태그 그룹들을 슬리버로 렌더링
        ...tagGroups.map((group) => _buildTagGroupSliver(context, ref, group)),

        // 하단 여백
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  /// 개별 태그 그룹을 슬리버로 구성
  Widget _buildTagGroupSliver(
    BuildContext context,
    WidgetRef ref,
    TagGroupReadWithTags group,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        // 그룹 헤더
        SliverToBoxAdapter(
          child: _buildTagGroupHeader(context, ref, group),
        ),

        // 태그 목록 (그룹 내)
        if (group.tags.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTagItem(
                context,
                ref,
                group.tags[index],
                group,
              ),
              childCount: group.tags.length,
            ),
          )
        else
          // 태그가 없는 경우
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      const Text('이 그룹에는 태그가 없습니다'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showCreateTagDialog(context, ref, group),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('태그 추가'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 태그 그룹 헤더 위젯
  Widget _buildTagGroupHeader(
    BuildContext context,
    WidgetRef ref,
    TagGroupReadWithTags group,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: ColorExt.fromHex(group.color),
              shape: BoxShape.circle,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (group.isTodoGroup)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TODO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: group.description != null
              ? Text(group.description!)
              : Text('${group.tags.length}개의 태그'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 태그 추가 버튼
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '태그 추가',
                onPressed: () => _showCreateTagDialog(context, ref, group),
                visualDensity: VisualDensity.compact,
              ),
              // 그룹 설정 버튼
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: '그룹 설정',
                onPressed: () => _showGroupSettingsSheet(context, ref, group),
                visualDensity: VisualDensity.compact,
              ),
              // 확장 아이콘 (ExpansionTile 기본)
              const SizedBox(width: 12),
            ],
          ),
          children: const [], // 실제 컨텐츠는 SliverList에서 처리
        ),
      ),
    );
  }

  /// 개별 태그 아이템 위젯
  Widget _buildTagItem(
    BuildContext context,
    WidgetRef ref,
    TagRead tag,
    TagGroupReadWithTags group,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Card(
        margin: EdgeInsets.zero,
        child: Dismissible(
          key: Key('tag_${tag.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) => _confirmDeleteTag(context, tag),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            ref.read(tagMutationsProvider.notifier).deleteTag(tag.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${tag.name} 태그가 삭제되었습니다'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: ListTile(
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: ColorExt.fromHex(tag.color),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(tag.name),
            subtitle: tag.description != null ? Text(tag.description!) : null,
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: '태그 수정',
              onPressed: () => _showEditTagDialog(context, ref, tag, group),
              visualDensity: VisualDensity.compact,
            ),
            onTap: () => _showEditTagDialog(context, ref, tag, group),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }

  /// 로딩 뷰
  Widget _buildLoadingView() {
    return const CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('태그를 불러오는 중...'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 에러 뷰
  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '태그를 불러올 수 없습니다',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
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
        ),
      ],
    );
  }

  /// 빈 상태 뷰
  Widget _buildEmptyView(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.label_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  '아직 태그가 없습니다',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  '태그 그룹을 만들어 태그를 정리해보세요',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _showCreateGroupDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('첫 태그 그룹 만들기'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Event Handlers
  // ============================================================

  /// 새 태그 그룹 생성 다이얼로그
  void _showCreateGroupDialog(BuildContext context) {
    showTagGroupFormSheet(context);
  }

  /// 새 태그 생성 다이얼로그
  void _showCreateTagDialog(
    BuildContext context,
    WidgetRef ref,
    TagGroupReadWithTags group,
  ) {
    final tagGroupsAsync = ref.read(tagTreeProvider);
    tagGroupsAsync.when(
      data: (groups) {
        showTagFormSheet(
          context,
          defaultGroupId: group.id,
          availableGroups: groups,
        );
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  /// 태그 수정 다이얼로그
  void _showEditTagDialog(
    BuildContext context,
    WidgetRef ref,
    TagRead tag,
    TagGroupReadWithTags group,
  ) {
    final tagGroupsAsync = ref.read(tagTreeProvider);
    tagGroupsAsync.when(
      data: (groups) {
        showTagFormSheet(
          context,
          tag: tag,
          availableGroups: groups,
        );
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  /// 그룹 설정 시트 (수정/삭제)
  void _showGroupSettingsSheet(
    BuildContext context,
    WidgetRef ref,
    TagGroupReadWithTags group,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _TagGroupSettingsSheet(group: group),
    );
  }

  /// 태그 삭제 확인
  Future<bool> _confirmDeleteTag(BuildContext context, TagRead tag) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('${tag.name} 태그를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

/// 태그 그룹 설정 시트
class _TagGroupSettingsSheet extends ConsumerWidget {
  final TagGroupReadWithTags group;

  const _TagGroupSettingsSheet({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // 제목
          Text(
            '${group.name} 그룹',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // 수정 버튼
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                showTagGroupFormSheet(context, tagGroup: group);
              },
              icon: const Icon(Icons.edit),
              label: const Text('그룹 수정'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 삭제 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDeleteGroup(context, ref),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('그룹 삭제', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 그룹 삭제 확인
  Future<void> _confirmDeleteGroup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 그룹 삭제'),
        content: Text(
          '${group.name} 그룹을 삭제하시겠습니까?\n'
          '이 그룹에 속한 ${group.tags.length}개의 태그도 함께 삭제됩니다.\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(); // 설정 시트 닫기

      try {
        await ref.read(tagMutationsProvider.notifier).deleteGroup(group.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${group.name} 그룹이 삭제되었습니다'),
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
}
