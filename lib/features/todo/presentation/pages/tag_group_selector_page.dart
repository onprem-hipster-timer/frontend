import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_card.dart';

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
            return AppEmptyState(
              icon: Icons.folder_off_outlined,
              title: '태그 그룹이 없습니다',
              message: '먼저 태그 그룹을 만들어주세요.\n그룹을 만든 후 할 일을 정리할 수 있습니다.',
              actionLabel: '새 그룹 만들기',
              onAction: () => showTagGroupFormSheet(context),
            );
          }

          return _TagGroupGrid(tagGroups: tagGroups);
        },
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorState(
          title: '태그 그룹을 불러오지 못했습니다',
          error: error,
          secondaryLabel: '돌아가기',
          onSecondary: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

/// 그룹 목록 끝의 '새 그룹 만들기' 카드
class _NewGroupCard extends StatelessWidget {
  const _NewGroupCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => showTagGroupFormSheet(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 36,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              '새 그룹 만들기',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 태그 그룹 카드 격자
class _TagGroupGrid extends StatelessWidget {
  const _TagGroupGrid({required this.tagGroups});

  final List<TagGroupRead> tagGroups;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 설명 텍스트
          const AppHintCard(message: '새로 만들 투두들이 속할 그룹을 선택해주세요.'),

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
              itemCount: tagGroups.length + 1,
              itemBuilder: (context, index) {
                if (index == tagGroups.length) return const _NewGroupCard();
                final tagGroup = tagGroups[index];
                return TodoGroupCard(
                  group: tagGroup,
                  onTap: () => Navigator.of(context).pop(tagGroup),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
