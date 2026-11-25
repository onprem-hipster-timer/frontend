import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent_step_view.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_meeting_b.dart';
import 'samples_turnstile.dart';

/// 동의를 기록하지 못했을 때 버튼 위에 뜨는 안내
const _messages = <String, String?>{
  '없음': null,
  '확인 실패': '사람인지 확인하지 못했습니다. 다시 시도해 주세요',
  '약관이 또 바뀜': '약관이 바뀌었습니다. 바뀐 내용을 확인하고 다시 동의해 주세요',
  '연결 끊김': '네트워크 연결을 확인해 주세요',
};

@widgetbook.UseCase(
  name: '게스트 약관 다시 동의',
  type: MeetingGuestConsentStepView,
  path: '[모임]/들어오기·계정',
)
Widget meetingGuestConsentStepView(BuildContext context) {
  final knobs = context.knobs;
  final agreed = knobs.boolean(
    label: '모두 체크한 채로 시작',
    description: "세 항목을 모두 체크해야 '동의하고 계속하기'를 누를 수 있다",
  );
  final turnstile = turnstileKnob(
    context,
    description: '사람 확인 상자(Cloudflare Turnstile) 상태',
  );
  final message = knobs.object.dropdown(
    label: '안내',
    options: _messages.keys.toList(),
    description: '동의를 기록하지 못하면 버튼 위에 까닭을 알린다. 약관이 또 바뀌었으면 체크를 모두 푼다',
  );
  final busy = knobs.boolean(
    label: '보내는 중',
    description: '누른 뒤 끝날 때까지 두 버튼을 누를 수 없다',
  );
  // 앱에서는 약관이 바뀐 뒤 게스트가 모임 화면을 열면 모임 대신 화면 가운데에 뜬다. '보기'는 약관 페이지를 새
  // 탭으로 여는데, 카탈로그에서는 아무것도 열지 않는다. 눌러도 아무 데도 가지 않는다
  return SampleProviderScope(
    overrides: [openLinkProvider.overrideWithValue((_) async {})],
    child: MeetingSampleHolder<GuestConsentChecks>(
      key: ValueKey(agreed),
      initial: (age: agreed, terms: agreed, privacy: agreed),
      builder: (consent, onChanged) => MeetingGuestConsentStepView(
        consent: consent,
        onConsentChanged: onChanged,
        turnstile: SampleTurnstileField(status: turnstile),
        message: _messages[message],
        busy: busy,
        onAgree: () {},
        onSignOut: () {},
      ),
    ),
  );
}
