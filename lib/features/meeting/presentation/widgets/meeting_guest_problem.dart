import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent_step.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_not_found.dart';
import 'package:momeet/shared/domain/terms.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 게스트가 모임을 볼 수 없을 때의 화면. 까닭은 요청 파이프라인이 게스트 상태에 적은 거절([denial])과
/// 불러오기 오류([error])다.
///
/// - 약관에 다시 동의해야 하면 동의를 받는다(확인 위젯이 없는 환경이면 로그아웃 길만).
/// - 모임이 지금 게스트를 받지 않으면 그렇다고 하고 다시 시도와 로그아웃을 둔다(게스트 정보는 남는다).
/// - 없는 모임이면 '모임을 찾을 수 없습니다'다.
/// - 그 밖에는 불러오지 못했다고 하고 [onRetry]와 로그아웃을 둔다.
///
/// 세션이 끝난 게스트는 미인증이 되어 방문자 화면이 되므로 여기에 오지 않는다.
class MeetingGuestProblem extends ConsumerWidget {
  const MeetingGuestProblem({
    super.key,
    required this.meetingId,
    required this.guest,
    required this.denial,
    required this.error,
    required this.onRetry,
  });

  final String meetingId;
  final GuestUser guest;
  final GuestDenial? denial;
  final Object? error;
  final VoidCallback onRetry;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, '로그아웃하지 못했습니다: $e', kind: AppNoticeKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAgree = ref.watch(turnstileFactoryProvider) != null;
    final error = this.error;
    return switch (denial) {
      GuestDenial.consentRequired when canAgree => MeetingGuestConsentStep(
        meetingId: meetingId,
        guest: guest,
        onAgreed: onRetry,
      ),
      GuestDenial.notAcceptingGuests => AppErrorState(
        title: '지금은 게스트로 이 ${Terms.meeting.withJosa('을', '를')} 볼 수 없습니다',
        error:
            '${Terms.meeting} 주인이 게스트 참여나 공개를 껐습니다. '
            '다시 열리면 남긴 시간 그대로 이어서 쓸 수 있습니다.',
        onRetry: onRetry,
        secondaryLabel: '로그아웃',
        secondaryIcon: Icons.logout,
        onSecondary: () => _signOut(context, ref),
      ),
      _ when error != null && isMeetingNotFound(error) =>
        const MeetingNotFound(),
      _ => AppErrorState(
        title: '${Terms.meeting.withJosa('을', '를')} 불러오지 못했습니다',
        error: error,
        onRetry: onRetry,
        secondaryLabel: '로그아웃',
        secondaryIcon: Icons.logout,
        onSecondary: () => _signOut(context, ref),
      ),
    };
  }
}
