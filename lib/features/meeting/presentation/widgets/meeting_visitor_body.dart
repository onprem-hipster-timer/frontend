import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_providers.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_link.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_availability_section.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_layout.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_link_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 로그인하지 않은 방문자의 모임 화면 본문: 공개 모임의 사람 수 격자, 로그인 상자, 참여자 수, 링크.
///
/// 이름은 어디에도 보이지 않는다(참여자 칩·선택된 일정이 없다). 격자를 칠하려 하면 로그인 상자를 보이게
/// 굴리고 떤다. 넓으면 로그인 상자가 오른쪽 칸 맨 위, 좁으면 격자 위다. 게스트를 받는 모임이고 확인 위젯이
/// 있으면(웹) 로그인 상자에 'Guest'를 두고, 누르면 그 자리에서 게스트 폼을 연다. 공개가 아니거나 없는
/// 모임은 같은 '모임을 찾을 수 없습니다'와 로그인이다.
class MeetingVisitorBody extends ConsumerStatefulWidget {
  const MeetingVisitorBody({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingVisitorBody> createState() => _MeetingVisitorBodyState();
}

class _MeetingVisitorBodyState extends ConsumerState<MeetingVisitorBody> {
  final _login = GlobalKey();
  var _shakes = 0;
  var _guestOpen = false;

  /// 칠하려 한 사람을 로그인 상자로 데려간다
  void _nudge() {
    setState(() => _shakes++);
    final box = _login.currentContext;
    if (box == null) return;
    Scrollable.ensureVisible(
      box,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  void _goToLogin() => goToLoginForMeeting(context, widget.meetingId);

  @override
  Widget build(BuildContext context) {
    final provider = meetingHeadcountProvider(widget.meetingId);
    return ref
        .watch(provider)
        .when(
          data: (headcount) {
            final availability = MeetingAvailabilitySection(
              meeting: headcount.meeting,
              shading: headcount,
              onLocked: _nudge,
            );
            final guests =
                headcount.meeting.allowGuests &&
                ref.watch(turnstileFactoryProvider) != null;
            final login = MeetingLoginPanel(
              key: _login,
              shakes: _shakes,
              onLogin: _goToLogin,
              onGuest: guests ? () => setState(() => _guestOpen = true) : null,
              guestForm: guests && _guestOpen
                  ? MeetingGuestForm(meetingId: widget.meetingId)
                  : null,
              onCloseGuest: () => setState(() => _guestOpen = false),
            );
            final participants = _HeadcountPanel(headcount.participantCount);
            final link = MeetingLinkPanel(meetingId: widget.meetingId);
            return MeetingLayout(
              main: availability,
              side: [login, participants, link],
              stacked: [login, availability, participants, link],
            );
          },
          loading: () => const AppLoading(),
          error: (error, _) => isMeetingNotFound(error)
              ? MeetingNotFound(onLogin: _goToLogin)
              : AppErrorState(
                  title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
                  error: error,
                  onRetry: () => ref.invalidate(provider),
                ),
        );
  }
}

/// 이름 없이 참여자 수만 보이는 '일정 참여자'
class _HeadcountPanel extends StatelessWidget {
  const _HeadcountPanel(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MeetingPanel(
      title: '일정 참여자',
      child: Text(
        count == 0 ? '아직 참여한 사람이 없습니다' : '$count명 참여 중',
        style: count == 0
            ? theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )
            : theme.textTheme.bodyLarge,
      ),
    );
  }
}
