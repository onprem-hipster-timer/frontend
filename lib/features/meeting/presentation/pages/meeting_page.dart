import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_member_body.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 모임 화면. 공유 링크(`/meetings/<id>`)로 열고, 탭 셸 밖에 있다. 본문은 [MeetingMemberBody]다.
class MeetingPage extends ConsumerWidget {
  const MeetingPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(
      meetingBoardProvider(
        meetingId,
      ).select((state) => state.value?.board.meeting.title),
    );
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.home_outlined),
                tooltip: '처음 화면으로',
                onPressed: () => context.goNamed(AppRoute.calendar.name),
              ),
        title: Text(title ?? Terms.meeting),
      ),
      body: MeetingMemberBody(meetingId: meetingId),
    );
  }
}
