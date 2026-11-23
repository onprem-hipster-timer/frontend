import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/features/mypage/presentation/widgets/meeting_entry_section.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meeting_tile.dart';
import 'package:momeet/features/mypage/presentation/widgets/my_meetings_skeleton.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 마이페이지에서 보이는 내 모임의 수. 넘으면 '모두 보기'로 전체 목록을 연다
const myMeetingsShown = 5;

/// '내 모임': 맨 위에 모임 만들기, 그 아래 내가 만든 모임을 새로 만든 순으로 [myMeetingsShown]개까지
/// ([MyMeetingTile]), 더 있으면 '모두 보기 (N)'. 불러오는 동안은 자리, 못 받으면 다시 시도, 없으면 아직 만든
/// 모임이 없다고 알린다
class MyMeetingsSection extends ConsumerWidget {
  const MyMeetingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내 ${Terms.meeting}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MeetingEntrySection(),
              const Divider(height: 1),
              ref
                  .watch(myMeetingsProvider)
                  .when(
                    data: (meetings) => meetings.isEmpty
                        ? const _Empty()
                        : _Shown(meetings: meetings),
                    loading: () => const MyMeetingsSkeleton(),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: AppErrorState(
                        title: myMeetingsLoadFailed,
                        onRetry: () => ref.invalidate(myMeetingsProvider),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 내 모임을 불러오지 못했을 때
final myMeetingsLoadFailed = '내 ${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다';

/// 만든 모임이 없을 때
const myMeetingsEmpty = '아직 만든 ${Terms.meeting}이 없어요';

/// 앞의 [myMeetingsShown]개와, 더 있으면 '모두 보기 (N)'
class _Shown extends StatelessWidget {
  const _Shown({required this.meetings});

  final List<MeetingRead> meetings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, meeting) in meetings.take(myMeetingsShown).indexed) ...[
          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
          MyMeetingTile(meeting: meeting),
        ],
        if (meetings.length > myMeetingsShown) ...[
          const Divider(height: 1),
          ListTile(
            title: Text(
              '모두 보기 (${meetings.length})',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.primary,
            ),
            onTap: () => context.goNamed(AppRoute.myMeetings.name),
          ),
        ],
      ],
    );
  }
}

/// 만든 모임이 없다(만들기는 바로 위에 있다)
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        myMeetingsEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
