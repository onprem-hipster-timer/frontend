import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/providers/tag_providers.dart';
import 'package:momeet/features/tag/presentation/widgets/tag_group_form_sheet.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_card.dart';

/// Todo 대시보드 페이지
///
/// 그룹들을 카드 형태로 표시하는 메인 페이지입니다.
/// 개별 Todo 항목은 표시하지 않고, 그룹 선택만 담당합니다.
class TodoDashboardPage extends ConsumerWidget {
  const TodoDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagGroupsAsync = ref.watch(tagGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일 관리'),
        elevation: 0,
        centerTitle: true,
      ),
      body: tagGroupsAsync.when(
        data: (tagGroups) {
          if (tagGroups.isEmpty) {
            return AppEmptyState(
              icon: Icons.folder_open_rounded,
              title: '그룹이 없습니다',
              message: '첫 번째 그룹을 만들어\n체계적으로 할 일을 관리해보세요!',
              actionLabel: '첫 그룹 만들기',
              onAction: () => _showCreateGroupDialog(context),
            );
          }

          return _GroupGrid(todoGroups: tagGroups);
        },
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorState(
          title: '그룹을 불러오지 못했습니다',
          error: error,
          onRetry: () => ref.invalidate(tagGroupsRawProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context),
        icon: const Icon(Icons.create_new_folder),
        label: const Text('새 그룹 만들기'),
        tooltip: '새 그룹 만들기',
      ),
    );
  }

  /// 새 그룹 생성 다이얼로그
  void _showCreateGroupDialog(BuildContext context) {
    showTagGroupFormSheet(context);
  }
}

/// 그룹 안내와 그룹 카드 격자
class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.todoGroups});

  final List<TagGroupRead> todoGroups;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 헤더 정보
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: const AppHintCard(
              title: '그룹 관리',
              message: '그룹을 선택해서 할 일들을 관리하세요.',
              icon: Icons.dashboard_rounded,
            ),
          ),
        ),

        // 그룹 그리드
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: TodoGroupCard.gridDelegate(context),
            delegate: SliverChildBuilderDelegate((context, index) {
              final group = todoGroups[index];
              return TodoGroupCard(
                group: group,
                onTap: () => context.goNamed(
                  AppRoute.todoGroupDetail.name,
                  pathParameters: {'groupId': group.id},
                ),
              );
            }, childCount: todoGroups.length),
          ),
        ),

        // 하단 여백 (FAB 가리지 않도록)
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
