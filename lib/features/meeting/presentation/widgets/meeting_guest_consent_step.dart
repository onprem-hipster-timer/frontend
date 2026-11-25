import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_field.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_steps.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent_step_view.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 약관이 바뀌어 게스트 경로가 거절됐을 때(428) 다시 동의를 받는다.
///
/// 지금 약관 버전은 게스트의 이름을 찾아(확인 상자의 토큰) 받고, 동의를 기록하면 게스트 상태의 약관 거절을
/// 지우고 [onAgreed]를 부른다.
/// 동의하지 않으면 로그아웃한다(게스트 정보는 남는다).
class MeetingGuestConsentStep extends ConsumerStatefulWidget {
  const MeetingGuestConsentStep({
    super.key,
    required this.meetingId,
    required this.guest,
    required this.onAgreed,
  });

  final String meetingId;
  final GuestUser guest;
  final VoidCallback onAgreed;

  @override
  ConsumerState<MeetingGuestConsentStep> createState() =>
      _MeetingGuestConsentStepState();
}

class _MeetingGuestConsentStepState
    extends ConsumerState<MeetingGuestConsentStep> {
  late final TurnstileController _turnstile = ref.read(
    turnstileFactoryProvider,
  )!();
  late final _steps = MeetingGuestSteps(
    meetingId: widget.meetingId,
    turnstile: _turnstile,
    guests: ref.read(guestsApiProvider),
    auth: ref.read(authProvider.notifier),
    analytics: () => ref.read(analyticsConsentProvider).asBool,
  );

  GuestConsentChecks _consent = (age: false, terms: false, privacy: false);
  var _busy = false;
  String? _message;

  @override
  void dispose() {
    _turnstile.dispose();
    super.dispose();
  }

  Future<void> _agree() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _steps.agree(widget.guest);
      ref.read(authProvider.notifier).guestDenialCleared();
      widget.onAgreed();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (GuestRefusal.of(error) == GuestRefusal.consentChanged) {
          _consent = (age: false, terms: false, privacy: false);
        }
        _message = guestRefusalText(error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authProvider.notifier).signOut();
    } on Exception catch (e) {
      if (mounted) {
        showAppSnackBar(context, '로그아웃하지 못했습니다: $e', kind: AppNoticeKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MeetingGuestConsentStepView(
      consent: _consent,
      onConsentChanged: (value) => setState(() => _consent = value),
      turnstile: TurnstileField(controller: _turnstile),
      message: _message,
      busy: _busy,
      onAgree: _agree,
      onSignOut: _signOut,
    );
  }
}
