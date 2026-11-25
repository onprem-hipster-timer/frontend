import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/auth_status.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent_step_view.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_problem_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_meeting_b.dart';
import 'samples_turnstile.dart';

const _reasons = <String, GuestDenial?>{
  '약관이 바뀜': GuestDenial.consentRequired,
  '게스트를 받지 않음': GuestDenial.notAcceptingGuests,
  '불러오지 못함': null,
};

@widgetbook.UseCase(
  name: '게스트가 모임을 볼 수 없음',
  type: MeetingGuestProblemView,
  path: '[모임]/들어오기·계정',
)
Widget meetingGuestProblemView(BuildContext context) {
  final reason = context.knobs.object.dropdown(
    label: '까닭',
    options: _reasons.keys.toList(),
    description:
        '약관이 바뀌었으면 다시 동의를 받는다. 주인이 게스트 참여나 공개를 껐으면 그렇다고 알리고, '
        "그 밖에는 불러오지 못했다고 한다. 없는 모임이면 '모임을 찾을 수 없음'과 같다",
  );
  // 앱에서는 게스트의 모임 화면에서 모임 대신 뜬다. '보기'는 약관 페이지를 새 탭으로 여는데, 카탈로그에서는
  // 아무것도 열지 않는다. 눌러도 아무 데도 가지 않는다
  return SampleProviderScope(
    overrides: [openLinkProvider.overrideWithValue((_) async {})],
    child: Scaffold(
      body: MeetingGuestProblemView(
        denial: _reasons[reason],
        error: '연결 시간이 초과되었습니다',
        consentStep: MeetingSampleHolder<GuestConsentChecks>(
          initial: (age: false, terms: false, privacy: false),
          builder: (consent, onChanged) => MeetingGuestConsentStepView(
            consent: consent,
            onConsentChanged: onChanged,
            turnstile: const SampleTurnstileField(
              status: TurnstileStatus.ready,
            ),
            message: null,
            busy: false,
            onAgree: () {},
            onSignOut: () {},
          ),
        ),
        onRetry: () {},
        onSignOut: () {},
      ),
    ),
  );
}
