import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/auth/guest_user.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_field.dart';
import 'package:momeet/features/meeting/presentation/providers/meeting_guest_steps.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_guest_errors.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/shared/ui/ui.dart';

/// 약관이 바뀌어 게스트 경로가 거절됐을 때(428) 다시 동의를 받는다.
///
/// 지금 약관 버전은 게스트의 이름을 찾아(확인 상자의 토큰) 받고, 동의를 기록한 뒤 [onAgreed]를 부른다.
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
  );

  GuestConsentChecks _consent = (age: false, terms: false, privacy: false);
  var _busy = false;
  String? _message;

  bool get _agreed => _consent.age && _consent.terms && _consent.privacy;

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
    final theme = Theme.of(context);
    final message = _message;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: MeetingPanel(
            title: '약관 동의',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '약관이 바뀌었습니다. 계속하려면 다시 동의해 주세요.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                MeetingGuestConsent(
                  value: _consent,
                  onChanged: (value) => setState(() => _consent = value),
                ),
                const SizedBox(height: 12),
                TurnstileField(controller: _turnstile),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy || !_agreed ? null : _agree,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('동의하고 계속하기'),
                ),
                TextButton(
                  onPressed: _busy ? null : _signOut,
                  child: const Text('동의하지 않고 로그아웃'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
