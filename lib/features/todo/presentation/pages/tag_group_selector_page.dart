import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/export.dart';
import 'package:momeet/features/tag/presentation/providers/tag_providers.dart';
import 'package:momeet/core/utils/color_utils.dart';

/// 태그 그룹 선택 페이지
///
/// 투두 그룹 생성 시 사용자가 어떤 태그 그룹에 속하게 할지 선택하는 페이지입니다.
/// 선택된 TagGroupRead 객체를 반환합니다.
class TagGroupSelectorPage extends ConsumerWidget {
  const TagGroupSelectorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tagGroupsAsync = ref.watch(tagGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('어떤 그룹에 만들까요?'),
        elevation: 0,
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: tagGroupsAsync.when(
        data: (tagGroups) {
          if (tagGroups.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return _buildTagGroupGrid(context, theme, tagGroups);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorState(context, theme, error),
      ),
    );
  }

  /// 태그 그룹 그리드 뷰
  Widget _buildTagGroupGrid(
    BuildContext context,
    ThemeData theme,
    List<TagGroupRead> tagGroups,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 설명 텍스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '새로 만들 투두들이 속할 그룹을 선택해주세요.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 그리드 뷰
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: tagGroups.length,
              itemBuilder: (context, index) {
                final tagGroup = tagGroups[index];
                return _buildTagGroupCard(context, theme, tagGroup);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 태그 그룹 카드
  Widget _buildTagGroupCard(
    BuildContext context,
    ThemeData theme,
    TagGroupRead tagGroup,
  ) {
    final groupColor = HexColor.fromHex(tagGroup.color);

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 선택된 그룹을 반환하고 페이지 닫기
          Navigator.of(context).pop(tagGroup);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: groupColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 그룹 색상 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: groupColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tagGroup.isTodoGroup
                        ? Icons.task_alt_rounded
                        : Icons.label_outline_rounded,
                    color: groupColor,
                    size: 24,
                  ),
                ),

                const SizedBox(height: 12),

                // 그룹 이름
                Text(
                  tagGroup.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // 그룹 설명 (있는 경우)
                if (tagGroup.description != null && tagGroup.description!.isNotEmpty) ...[
                  Text(
                    tagGroup.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Spacer(),

                // Todo 그룹 배지 (있는 경우)
                if (tagGroup.isTodoGroup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '할 일 그룹',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '태그 그룹이 없습니다',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '먼저 태그 그룹을 만들어주세요.\n그룹을 만든 후 할 일을 정리할 수 있습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // 현재 페이지를 닫고 사용자에게 태그 관리 페이지에서 그룹을 만들라고 안내
                Navigator.of(context).pop();

                // 태그 그룹 생성 안내 스낵바 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('태그 관리 페이지에서 그룹을 먼저 만들어주세요.'),
                    action: SnackBarAction(
                      label: '확인',
                      onPressed: () {},
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );

                // TODO: 프로젝트의 라우팅 구조에 맞게 수정 필요
                // 예시: context.push('/tag-management');
                // 또는: Navigator.of(context).pushNamed('/tag-management');
              },
              icon: const Icon(Icons.add),
              label: const Text('태그 그룹 만들러 가기'),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 상태 위젯
  Widget _buildErrorState(BuildContext context, ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              '태그 그룹을 불러오지 못했습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
