import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/features/auth/presentation/widgets/consent_check_tile.dart';

/// 게스트가 체크한 약관 동의 세 항목
typedef GuestConsentChecks = ({bool age, bool terms, bool privacy});

/// 게스트의 약관 동의: 전체 동의와 필수 세 항목 (회원 동의와 같은 문구·링크)
class MeetingGuestConsent extends StatelessWidget {
  const MeetingGuestConsent({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final GuestConsentChecks value;
  final ValueChanged<GuestConsentChecks> onChanged;

  @override
  Widget build(BuildContext context) {
    final all = value.age && value.terms && value.privacy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConsentCheckTile(
          label: ConsentLabels.all,
          emphasized: true,
          value: all,
          onChanged: (checked) =>
              onChanged((age: checked, terms: checked, privacy: checked)),
        ),
        const Divider(height: 1),
        ConsentCheckTile(
          label: ConsentLabels.ageOver14,
          value: value.age,
          onChanged: (checked) => onChanged((
            age: checked,
            terms: value.terms,
            privacy: value.privacy,
          )),
        ),
        ConsentCheckTile(
          label: ConsentLabels.terms,
          link: LegalLinks.terms,
          value: value.terms,
          onChanged: (checked) => onChanged((
            age: value.age,
            terms: checked,
            privacy: value.privacy,
          )),
        ),
        ConsentCheckTile(
          label: ConsentLabels.privacy,
          link: LegalLinks.privacy,
          value: value.privacy,
          onChanged: (checked) =>
              onChanged((age: value.age, terms: value.terms, privacy: checked)),
        ),
      ],
    );
  }
}
