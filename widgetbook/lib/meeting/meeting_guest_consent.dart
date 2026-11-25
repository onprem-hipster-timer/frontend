import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';

@widgetbook.UseCase(
  name: '게스트 약관 동의',
  type: MeetingGuestConsent,
  path: '[모임]/들어오기·계정',
)
Widget meetingGuestConsent(BuildContext context) {
  final agreed = context.knobs.boolean(
    label: '모두 체크한 채로 시작',
    description:
        '처음 쓰는 닉네임으로 들어올 때 비밀번호 칸 아래에 빈 채로 뜬다. 전체 동의를 누르면 세 항목이 함께 바뀐다',
  );
  // '보기'는 약관 페이지를 새 탭으로 여는데, 카탈로그에서는 아무것도 열지 않는다
  return SampleProviderScope(
    overrides: [openLinkProvider.overrideWithValue((_) async {})],
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _Consent(initial: (age: agreed, terms: agreed, privacy: agreed)),
    ),
  );
}

/// 누르면 체크가 바뀌도록 체크 상태를 여기서 가진다
class _Consent extends StatefulWidget {
  const _Consent({required this.initial});

  final GuestConsentChecks initial;

  @override
  State<_Consent> createState() => _ConsentState();
}

class _ConsentState extends State<_Consent> {
  late var _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MeetingGuestConsent(
      value: _value,
      onChanged: (value) => setState(() => _value = value),
    );
  }
}
