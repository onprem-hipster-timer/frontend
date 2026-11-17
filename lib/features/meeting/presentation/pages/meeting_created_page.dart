import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_date_badge.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_home_button.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 모임을 만든 뒤 화면(탭 셸 밖). 링크를 복사하거나 내 시간을 넣으러 모임 화면(주소도 그 모임 링크)으로 간다
class MeetingCreatedPage extends ConsumerWidget {
  const MeetingCreatedPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meeting = ref.watch(meetingProvider(meetingId)).value;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: meetingAppBarLeading(context),
        title: const Text('새 ${Terms.meeting}'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${Terms.meeting} 생성이 완료되었어요 :)',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(child: MeetingDateBadge(day: meeting?.startDate)),
                const SizedBox(height: 32),
                FilledButton.tonal(
                  onPressed: () => copyMeetingLink(context, ref, meetingId),
                  child: const Text('링크 공유'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.goNamed(
                    AppRoute.meeting.name,
                    pathParameters: {'meetingId': meetingId},
                  ),
                  child: const Text('나의 일정 입력'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
