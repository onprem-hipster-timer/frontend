import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/app_route.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_leave.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_member_body.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_visitor_body.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 모임 화면. 공유 링크(`/meetings/<id>`)로 열고, 탭 셸 밖에 있다.
///
/// 로그인했거나 이 모임의 게스트면 내 시간을 칠하고 이름을 보는 본문([MeetingMemberBody]), 아니면 공개 모임의
/// 사람 수만 보는 방문자 본문([MeetingVisitorBody])이다. 보는 중에 세션이 끝나면 방문자 본문으로 바뀐다.
class MeetingPage extends ConsumerWidget {
  const MeetingPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(
      currentUserProvider.select((user) => user != null),
    );
    final guest = ref.watch(currentGuestProvider);
    // 자기를 지우는 게스트는 되돌리기를 기다리는 동안에도 방문자 화면을 본다
    final leaving = ref.watch(meetingGuestLeavingProvider);
    final signedIn = member || (guest != null && !leaving);
    final title = signedIn
        ? ref.watch(
            meetingBoardProvider(
              meetingId,
            ).select((state) => state.value?.board.meeting.title),
          )
        : ref.watch(
            meetingHeadcountProvider(
              meetingId,
            ).select((state) => state.value?.meeting.title),
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
      body: signedIn
          ? MeetingMemberBody(meetingId: meetingId, guest: guest)
          : MeetingVisitorBody(meetingId: meetingId),
    );
  }
}
