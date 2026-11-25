import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_kept_guest_notice.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_request.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_visitor_body_view.dart';

/// 로그인하지 않은 방문자의 모임 화면 본문: 공개 모임의 사람 수 격자, 로그인, 참여자 수, 링크.
///
/// 이름은 어디에도 보이지 않는다(참여자 칩·선택된 일정이 없다). 게스트를 받는 모임이고 확인 위젯이 있으면(웹)
/// 로그인 옆에 'Guest'를 두고, 누르면 그 자리에서 게스트 폼을 연다.
///
/// 넓으면 로그인 상자가 오른쪽 칸 맨 위에 있고, 칠하려 하면 그 상자를 보이게 굴리고 떤다. 좁으면 먼저 격자를
/// 보고 만져 보게 로그인 상자를 두지 않는다: 화면 아래에 '내 시간 입력하기'를 붙여 두고, 그것을 누르거나
/// 칠하려 하면 그때 요청 시트([showMeetingLoginRequest])를 올린다. 공개가 아니거나 없는 모임은 같은
/// '모임을 찾을 수 없습니다'와 로그인이다.
///
/// 모양은 [MeetingVisitorBodyView]
class MeetingVisitorBody extends ConsumerStatefulWidget {
  const MeetingVisitorBody({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingVisitorBody> createState() => _MeetingVisitorBodyState();
}

class _MeetingVisitorBodyState extends ConsumerState<MeetingVisitorBody> {
  void _goToLogin() => goToLoginForMeeting(context, widget.meetingId);

  void _request({required bool guests}) {
    ref.read(usageAnalyticsProvider).event(UsageEvent.meetingLoginRequestShown);
    showMeetingLoginRequest(
      context,
      meetingId: widget.meetingId,
      guests: guests,
      onLogin: _goToLogin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = meetingHeadcountProvider(widget.meetingId);
    final headcount = ref.watch(provider);
    final guests =
        headcount.whenOrNull(
          data: (headcount) =>
              headcount.meeting.allowGuests &&
              ref.watch(turnstileFactoryProvider) != null,
        ) ??
        false;
    return MeetingVisitorBodyView(
      headcount: headcount,
      guests: guests,
      keptGuestNotice: MeetingKeptGuestNotice(meetingId: widget.meetingId),
      guestForm: MeetingGuestForm(meetingId: widget.meetingId),
      link: (title) =>
          MeetingLinkPanel(meetingId: widget.meetingId, title: title),
      onLogin: _goToLogin,
      onNudged: () => ref
          .read(usageAnalyticsProvider)
          .event(UsageEvent.meetingLoginRequestShown),
      onRequest: () => _request(guests: guests),
      onRetry: () => ref.invalidate(provider),
    );
  }
}
