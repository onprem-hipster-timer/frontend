import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_timezone_label.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 화면. 공유 링크(`/meetings/<id>`)로 열고, 탭 셸 밖에 있다
class MeetingPage extends ConsumerWidget {
  const MeetingPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meeting = ref.watch(meetingProvider(meetingId));
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: '처음 화면으로',
                onPressed: () => context.goNamed(AppRoute.calendar.name),
              ),
        title: const Text(Terms.meeting),
      ),
      body: meeting.when(
        data: (meeting) => _MeetingSummary(meeting: meeting),
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(
          title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
          error: error,
          onRetry: () => ref.invalidate(meetingProvider(meetingId)),
        ),
      ),
    );
  }
}

/// 제목, 기간, 시간을 받는 방식, 시간 기준
class _MeetingSummary extends StatelessWidget {
  const _MeetingSummary({required this.meeting});

  final MeetingRead meeting;

  @override
  Widget build(BuildContext context) {
    final mode = inferMeetingMode(meeting);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meeting.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _InfoLine(
                icon: Icons.event_outlined,
                text: meetingPeriodText(meeting),
              ),
              _InfoLine(
                icon: Icons.schedule,
                text: mode == MeetingMode.hourly
                    ? '${meetingModeLabel(mode)} · ${meetingHoursText(meeting)}'
                    : meetingModeLabel(mode),
              ),
              const SizedBox(height: 8),
              MeetingTimezoneLabel(meeting.timezone),
            ],
          ),
        ),
      ),
    );
  }
}

/// 아이콘과 글 한 줄
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
