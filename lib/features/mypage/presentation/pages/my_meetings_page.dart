import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meeting_tile.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meetings_section.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 내 모임 전체 목록(`/mypage/meetings`, 마이페이지의 '모두 보기'). 새로 만든 순이고, 누르면 모임 화면을 위에 연다
class MyMeetingsPage extends ConsumerWidget {
  const MyMeetingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 ${Terms.meeting}')),
      body: ref
          .watch(myMeetingsProvider)
          .when(
            data: (meetings) => meetings.isEmpty
                ? AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: myMeetingsEmpty,
                    actionLabel: '${Terms.meeting} 만들기',
                    actionIcon: Icons.add,
                    onAction: () => context.pushNamed(AppRoute.meetings.name),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: meetings.length,
                    separatorBuilder: (context, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) =>
                        MyMeetingTile(meeting: meetings[i]),
                  ),
            loading: () => const AppLoading(),
            error: (error, _) => AppErrorState(
              title: myMeetingsLoadFailed,
              error: error,
              onRetry: () => ref.invalidate(myMeetingsProvider),
            ),
          ),
    );
  }
}
