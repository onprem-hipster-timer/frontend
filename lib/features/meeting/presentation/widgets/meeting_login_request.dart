import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/auth_selectors.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_request_view.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 좁은 화면의 방문자가 칠하려 하거나 '내 시간 입력하기'를 누르면 올리는 요청 시트를 연다. 애니메이션을
/// 줄였으면 움직이지 않고 뜬다.
///
/// '로그인'을 고르면 시트를 닫고 [onLogin]을 부른다. [guests]면 'Guest'가 시트 안에서 게스트 폼을 연다.
Future<void> showMeetingLoginRequest(
  BuildContext context, {
  required String meetingId,
  required bool guests,
  required VoidCallback onLogin,
}) async {
  final login = await showAppSheet<bool>(
    context,
    animationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) =>
        MeetingLoginRequest(meetingId: meetingId, guests: guests),
  );
  if (login == true && context.mounted) onLogin();
}

/// 요청 시트의 내용: '내 시간 입력하기', 까닭, 로그인·Guest. Guest는 그 자리에서 게스트 폼('뒤로'로
/// 고르기로 돌아간다)이고, 게스트로 들어가면 시트를 닫는다. '로그인'은 true로 닫는다.
class MeetingLoginRequest extends ConsumerStatefulWidget {
  const MeetingLoginRequest({
    super.key,
    required this.meetingId,
    required this.guests,
  });

  final String meetingId;
  final bool guests;

  @override
  ConsumerState<MeetingLoginRequest> createState() =>
      _MeetingLoginRequestState();
}

class _MeetingLoginRequestState extends ConsumerState<MeetingLoginRequest> {
  var _guestOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(currentGuestProvider, (_, guest) {
      if (guest != null) Navigator.of(context).pop();
    });
    return MeetingLoginRequestView(
      guestForm: _guestOpen
          ? MeetingGuestForm(meetingId: widget.meetingId)
          : null,
      onBack: () => setState(() => _guestOpen = false),
      onLogin: () => Navigator.of(context).pop(true),
      onGuest: widget.guests ? () => setState(() => _guestOpen = true) : null,
    );
  }
}
