import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_consent.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_form_view.dart';

import 'samples_turnstile.dart';

/// 게스트 폼에서 입력한 닉네임을 찾은 결과
enum GuestNameState {
  /// 아직 찾지 않았다
  unknown('찾기 전'),

  /// 찾는 중
  checking('찾는 중'),

  /// 이미 참여한 닉네임(들어가기)
  known('이미 참여한 닉네임'),

  /// 처음 쓰는 닉네임(약관 동의 뒤 참여하기)
  fresh('처음 쓰는 닉네임');

  const GuestNameState(this.label);

  /// 노브에 보이는 이름
  final String label;
}

/// 게스트 폼([MeetingGuestFormView]). 닉네임·비밀번호 칸과 약관 체크가 입력에 반응하도록 값을 들고 있고,
/// 들어가기를 누르면 칸만 검사한다. 노브를 바꿔 처음부터 다시 보이려면 부르는 쪽이 [key]를 바꾼다
class SampleGuestForm extends StatefulWidget {
  const SampleGuestForm({
    super.key,
    this.nameState = GuestNameState.unknown,
    this.turnstile = TurnstileStatus.ready,
    this.message,
    this.passwordError,
    this.busy = false,
  });

  final GuestNameState nameState;
  final TurnstileStatus turnstile;
  final String? message;
  final String? passwordError;
  final bool busy;

  @override
  State<SampleGuestForm> createState() => _SampleGuestFormState();
}

class _SampleGuestFormState extends State<SampleGuestForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: switch (widget.nameState) {
      GuestNameState.unknown => '',
      GuestNameState.known => '모모',
      GuestNameState.checking || GuestNameState.fresh => '다람쥐',
    },
  );
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  GuestConsentChecks _consent = (age: false, terms: false, privacy: false);

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _nameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.nameState;
    return MeetingGuestFormView(
      formKey: _formKey,
      nameController: _name,
      nameFocusNode: _nameFocus,
      passwordController: _password,
      passwordFocusNode: _passwordFocus,
      known: state == GuestNameState.known,
      checking: state == GuestNameState.checking,
      isNew: state == GuestNameState.fresh,
      consent: _consent,
      onConsentChanged: (value) => setState(() => _consent = value),
      turnstile: SampleTurnstileField(status: widget.turnstile),
      message: widget.message,
      passwordError: widget.passwordError,
      busy: widget.busy,
      onSubmit: () => _formKey.currentState!.validate(),
    );
  }
}

/// '로그인'·'Guest' 고르기와 게스트 폼이 읽는 Provider. 고른 것을 어디에도 보내지 않고, 약관 '보기'는 아무것도
/// 열지 않는다
final guestEntryOverrides = <Override>[
  usageAnalyticsProvider.overrideWithValue(const _NoUsageAnalytics()),
  openLinkProvider.overrideWithValue((_) async {}),
];

class _NoUsageAnalytics implements UsageAnalytics {
  const _NoUsageAnalytics();

  @override
  void event(UsageEvent event) {}

  @override
  void tag(UsageTag tag) {}
}
