import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_leave.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_glass_scaffold.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_member_body.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_visitor_body.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 모임 화면. 공유 링크(`/meetings/<id>`)로 열고, 탭 셸 밖에 있다.
///
/// 로그인했거나 이 모임의 게스트면 내 시간을 칠하고 이름을 보는 본문([MeetingMemberBody]), 아니면 공개 모임의
/// 사람 수만 보는 방문자 본문([MeetingVisitorBody])이다. 보는 중에 세션이 끝나면 방문자 본문으로 바뀌고, 거절된
/// 게스트가 지워진 것이면 그렇다고 알린다.
class MeetingPage extends ConsumerStatefulWidget {
  const MeetingPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends ConsumerState<MeetingPage> {
  /// 사용성 분석에 마지막으로 알린 계정 종류
  MeetingAccountTag? _reported;

  /// 계정 종류가 바뀌면 세션 태그로 알리고, 회원이 되면 도착을 알린다
  void _report(MeetingAccountTag account) {
    if (account == _reported) return;
    _reported = account;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(usageAnalyticsProvider)..tag(account);
      if (account == MeetingAccountTag.member) {
        analytics.event(UsageEvent.meetingMemberArrived);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 거절된 게스트를 확인해 보니 지워졌으면(파이프라인이 미인증으로 바꾼다) 그 까닭을 알린다
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      if (next is AuthUnauthenticated &&
          next.reason == AuthEndReason.guestRemoved &&
          previous != next) {
        showAppSnackBar(context, '이 ${Terms.meeting}의 게스트 정보가 지워졌습니다');
      }
    });
    final meetingId = widget.meetingId;
    final member = ref.watch(
      currentUserProvider.select((user) => user != null),
    );
    final guest = ref.watch(currentGuestProvider);
    // 자기를 지우는 게스트는 되돌리기를 기다리는 동안에도 방문자 화면을 본다
    final leaving = ref.watch(meetingGuestLeavingProvider);
    final signedIn = member || (guest != null && !leaving);
    _report(
      member
          ? MeetingAccountTag.member
          : signedIn
          ? MeetingAccountTag.guest
          : MeetingAccountTag.visitor,
    );
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
    return MeetingGlassScaffold(
      title: Text(title ?? Terms.meeting),
      body: signedIn
          ? MeetingMemberBody(meetingId: meetingId, guest: guest)
          : MeetingVisitorBody(meetingId: meetingId),
    );
  }
}
