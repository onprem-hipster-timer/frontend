import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart'
    show ShellMenuButton, ShellScope;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/tag_group_with_tags.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_form_sheet.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/core/utils/color_utils.dart';
import 'package:momeet/shared/ui/ui.dart';

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
        leading: ShellScope.compactOf(context) ? const ShellMenuButton() : null,
        title: const Text('태그 관리'),
        elevation: 0,
        centerTitle: true,
      ),
      body: tagTreeAsync.when(
        data: (tagGroups) => tagGroups.isEmpty
            ? AppEmptyState(
                icon: Icons.label_outline,
                title: '아직 태그가 없습니다',
                message: '태그 그룹을 만들어 태그를 정리해보세요',
                actionLabel: '첫 태그 그룹 만들기',
                onAction: () => showTagGroupFormSheet(context),
              )
            : CustomScrollView(
                slivers: [
                  SliverList.builder(
                    itemCount: tagGroups.length,
                    itemBuilder: (context, index) =>
                        _TagGroupCard(tagGroup: tagGroups[index]),
                  ),
                  // 새 그룹 버튼이 마지막 그룹을 가리지 않게 비운다
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
        loading: () => const AppLoading(message: '태그를 불러오는 중...'),
        error: (error, stack) => AppErrorState(
          title: '태그를 불러올 수 없습니다',
          error: error,
          onRetry: () => ref.invalidate(tagGroupsRawProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTagGroupFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('새 그룹'),
        tooltip: '새 태그 그룹 만들기',
      ),
    );
  }
}

/// 태그 그룹 카드. 펼치면 그룹의 태그 목록을 보인다.
class _TagGroupCard extends StatelessWidget {
  const _TagGroupCard({required this.tagGroup});

  final TagGroupWithTags tagGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
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
              _GroupActions(tagGroup: tagGroup),
            ],
          ),

          // 하위 태그 목록
          children: tagGroup.tags.map((tag) => _TagTile(tag: tag)).toList(),
        ),
      ),
    );
  }
}

/// 그룹의 태그 추가·수정·삭제 버튼 줄
class _GroupActions extends ConsumerWidget {
  const _GroupActions({required this.tagGroup});

  final TagGroupWithTags tagGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 태그 추가 버튼 (주요 액션)
        FilledButton.icon(
          onPressed: () =>
              showTagFormSheet(context, defaultGroupId: tagGroup.groupId),
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            '태그 추가',
            semanticsLabel: '${tagGroup.groupName} 그룹에 태그 추가',
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),

        // 그룹 수정 버튼
        OutlinedButton.icon(
          onPressed: () => _editGroup(context),
          icon: const Icon(Icons.edit, size: 16),
          label: Text('그룹 수정', semanticsLabel: '${tagGroup.groupName} 그룹 수정'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),

        // 그룹 삭제 버튼
        OutlinedButton.icon(
          onPressed: () => _deleteGroup(context, ref),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: Text('그룹 삭제', semanticsLabel: '${tagGroup.groupName} 그룹 삭제'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _editGroup(BuildContext context) {
    // TagGroupReadWithTags를 생성하여 전달
    final groupWithTags = TagGroupReadWithTags(
      id: tagGroup.groupId,
      name: tagGroup.groupName,
      color: tagGroup.groupColor,
      createdAt: tagGroup.createdAt,
      updatedAt: tagGroup.updatedAt,
      description: tagGroup.groupDescription,
      tags: tagGroup.tags,
    );

    showTagGroupFormSheet(context, tagGroup: groupWithTags);
  }

  Future<void> _deleteGroup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '그룹 삭제',
      content:
          '${tagGroup.groupName} 그룹을 삭제하시겠습니까?\n'
          '되돌릴 수 없습니다.\n'
          '그룹에 포함된 모든 태그도 함께 삭제됩니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        await deleteTagGroupMutation.run(
          ref,
          (tsx) => tsx
              .get(tagGroupsRawProvider.notifier)
              .deleteGroup(tagGroup.groupId),
        );

        if (context.mounted) {
          showAppSnackBar(context, '${tagGroup.groupName} 그룹이 삭제되었습니다');
        }
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            '그룹 삭제에 실패했습니다: $error',
            kind: AppNoticeKind.error,
          );
        }
      }
    }
  }
}

/// 태그 한 줄. 누르면 수정 시트를 연다.
class _TagTile extends ConsumerWidget {
  const _TagTile({required this.tag});

  final TagRead tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final description = tag.description;
    final actions = AppEditDeleteButtons(
      itemName: '${tag.name} 태그',
      onEdit: () => showTagFormSheet(context, tag: tag),
      onDelete: () => _deleteTag(context, ref),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // 버튼을 옆에 두면 이름 칸이 너무 좁아지는 폭이면 버튼을 이름 아래로 내린다
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = _crowds(context, constraints.maxWidth);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: HexColor.fromHex(tag.color),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(tag.name, style: theme.textTheme.bodyLarge),
            subtitle: narrow || (description?.isNotEmpty ?? false)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (description?.isNotEmpty ?? false) Text(description!),
                      if (narrow)
                        Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  )
                : null,
            trailing: narrow ? null : actions,
            onTap: () => showTagFormSheet(context, tag: tag),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            tileColor: theme.colorScheme.surface,
            hoverColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.1,
            ),
          );
        },
      ),
    );
  }

  /// [width] 폭의 줄에 버튼을 옆에 두면 이름 칸이 글자 배율을 반영한 최소 폭(140)보다 좁아지는지.
  /// 줄 안쪽 여백 32, 색 점과 사이 32, 이름과 버튼 사이 16을 뺀다
  static bool _crowds(BuildContext context, double width) =>
      width - 32 - 32 - 16 - AppEditDeleteButtons.widthOf(context) <
      MediaQuery.textScalerOf(context).scale(140);

  Future<void> _deleteTag(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '태그 삭제',
      content:
          '${tag.name} 태그를 삭제하시겠습니까?\n'
          '되돌릴 수 없습니다.',
      confirmText: '삭제',
      destructive: true,
    );

    if (confirmed == true && context.mounted) {
      try {
        await deleteTagMutation.run(
          ref,
          (tsx) => tsx.get(tagGroupsRawProvider.notifier).deleteTag(tag.id),
        );

        if (context.mounted) {
          showAppSnackBar(context, '${tag.name} 태그가 삭제되었습니다');
        }
      } catch (error) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            '태그 삭제에 실패했습니다: $error',
            kind: AppNoticeKind.error,
          );
        }
      }
    }
  }
}
