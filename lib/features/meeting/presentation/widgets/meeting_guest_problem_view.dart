import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/auth_status.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 게스트가 모임을 볼 수 없을 때의 화면. 까닭은 거절([denial])과 불러오기 오류([error])다.
///
/// - 약관에 다시 동의해야 하면 [consentStep]이다(없으면 아래의 불러오지 못함과 로그아웃).
/// - 모임이 지금 게스트를 받지 않으면 그렇다고 하고 다시 시도와 로그아웃을 둔다.
/// - 없는 모임이면 '모임을 찾을 수 없습니다'다.
/// - 그 밖에는 불러오지 못했다고 하고 [onRetry]와 로그아웃을 둔다.
class MeetingGuestProblemView extends StatelessWidget {
  const MeetingGuestProblemView({
    super.key,
    required this.denial,
    required this.error,
    required this.consentStep,
    required this.onRetry,
    required this.onSignOut,
  });

  final GuestDenial? denial;
  final Object? error;

  /// 약관에 다시 동의받는 화면. 받을 수 없는 환경이면 null
  final Widget? consentStep;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final consentStep = this.consentStep;
    return switch (denial) {
      GuestDenial.consentRequired when consentStep != null => consentStep,
      GuestDenial.notAcceptingGuests => AppErrorState(
        title: '지금은 게스트로 이 ${Terms.meeting.withJosa('을', '를')} 볼 수 없습니다',
        error:
            '${Terms.meeting} 주인이 게스트 참여나 공개를 껐습니다. '
            '다시 열리면 남긴 시간 그대로 이어서 쓸 수 있습니다.',
        onRetry: onRetry,
        secondaryLabel: '로그아웃',
        secondaryIcon: Icons.logout,
        onSecondary: onSignOut,
      ),
      _ when error != null && isMeetingNotFound(error) =>
        const MeetingNotFound(),
      _ => AppErrorState(
        title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
        error: error,
        onRetry: onRetry,
        secondaryLabel: '로그아웃',
        secondaryIcon: Icons.logout,
        onSecondary: onSignOut,
      ),
    };
  }
}
