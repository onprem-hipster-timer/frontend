import 'package:material_ui/material_ui.dart';
import 'package:momeet/shared/widgets/scaffold_with_nav.dart'
    show ShellMenuButton, ShellScope;
import 'package:momeet/shared/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:momeet/router.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/todo/presentation/providers/todo_group_providers.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_form_sheet.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_card.dart';
import 'package:momeet/features/todo/presentation/widgets/todo_group_form_sheet.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 할 일 대시보드 페이지
///
/// 할 일 그룹들을 카드로 보이는 할 일 탭의 첫 화면이다. 기본 그룹이 맨 앞에 오고, 끝 카드로 새 그룹을 만든다.
/// 할 일 추가는 기본 그룹에 넣는다.
class TodoDashboardPage extends ConsumerWidget {
  const TodoDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(todoGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: ShellScope.compactOf(context) ? const ShellMenuButton() : null,
        title: const Text('${Terms.todo} 관리'),
        elevation: 0,
        centerTitle: true,
      ),
      body: groupsAsync.when(
        data: (groups) => _GroupGrid(groups: groups),
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorState(
          title: '${Terms.todoGroup.withJosa('을', '를')} 불러오지 못했습니다',
          error: error,
          onRetry: () => ref.invalidate(todoGroupsProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTodoFormSheet(
          context,
          defaultTodoGroupId: defaultTodoGroupOf(groupsAsync.value)?.id,
        ),
        icon: const Icon(Icons.add_task),
        label: const Text('${Terms.todo} 추가'),
        tooltip: '${Terms.todo} 추가',
      ),
    );
  }
}

/// 그룹 안내와 할 일 그룹 카드 격자. 끝 칸은 새 그룹 만들기
class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.groups});

  final List<TodoGroupRead> groups;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AppHintCard(
              title: '${Terms.todoGroup} 관리',
              message:
                  '${Terms.todoGroup.withJosa('을', '를')} 선택해서 ${Terms.todo}들을 관리하세요.',
              icon: Icons.dashboard_rounded,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: TodoGroupCard.gridDelegate(context),
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == groups.length) return const _NewGroupCard();
              final group = groups[index];
              return TodoGroupCard(
                group: group,
                onTap: () => context.goNamed(
                  AppRoute.todoGroupDetail.name,
                  pathParameters: {'groupId': group.id},
                ),
              );
            }, childCount: groups.length + 1),
          ),
        ),

        // 하단 여백 (FAB 가리지 않도록)
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

/// 격자 끝의 새 할 일 그룹 만들기 카드
class _NewGroupCard extends StatelessWidget {
  const _NewGroupCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () => showTodoGroupFormSheet(context),
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
              '새 ${Terms.todoGroup}',
              textAlign: TextAlign.center,
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
