import 'package:material_ui/material_ui.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_panel.dart';

/// 약관이 바뀌어 다시 받는 게스트의 동의: 안내, 약관 체크, 사람 확인 상자([turnstile]), 거절 안내([message]),
/// '동의하고 계속하기'(모두 체크해야 누를 수 있다)와 '동의하지 않고 로그아웃'. [busy]면 둘 다 누를 수 없다
class MeetingGuestConsentStepView extends StatelessWidget {
  const MeetingGuestConsentStepView({
    super.key,
    required this.consent,
    required this.onConsentChanged,
    required this.turnstile,
    required this.message,
    required this.busy,
    required this.onAgree,
    required this.onSignOut,
  });

  final GuestConsentChecks consent;
  final ValueChanged<GuestConsentChecks> onConsentChanged;

  /// 사람 확인 상자
  final Widget turnstile;

  /// 동의를 기록하지 못한 까닭. 없으면 null
  final String? message;

  /// 보내는 중
  final bool busy;
  final VoidCallback onAgree;
  final VoidCallback onSignOut;

  bool get _agreed => consent.age && consent.terms && consent.privacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = this.message;
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
                  value: consent,
                  onChanged: onConsentChanged,
                ),
                const SizedBox(height: 12),
                turnstile,
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
                  onPressed: busy || !_agreed ? null : onAgree,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('동의하고 계속하기'),
                ),
                TextButton(
                  onPressed: busy ? null : onSignOut,
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
