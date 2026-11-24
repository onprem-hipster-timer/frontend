import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_guest_form.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:momeet/shared/api/kratos/kratos_client.dart';
import 'package:momeet/shared/api/kratos/kratos_models.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_turnstile.dart';

@widgetbook.UseCase(
  name: '로그인 상자',
  type: MeetingLoginPanel,
  path: '[모임]/들어오기·계정',
)
Widget meetingLoginPanel(BuildContext context) {
  final knobs = context.knobs;
  final guests = knobs.boolean(
    label: '게스트 받기',
    initialValue: true,
    description: "게스트를 받는 모임이면 '로그인' 옆에 'Guest'와 그 안내를 둔다",
  );
  final guestOpen = knobs.boolean(
    label: '게스트 폼 펼침',
    description:
        "'Guest'를 누르면 그 자리에서 게스트 폼으로 바뀐다. 닉네임 칸을 벗어나면 이름을 찾는다: "
        "'모모'는 이미 참여한 닉네임(들어가기), 다른 이름은 처음 쓰는 닉네임(약관 동의 뒤 참여하기)",
  );
  final turnstile = turnstileKnob(
    context,
    description: '게스트 폼의 사람 확인 상자(Cloudflare Turnstile) 상태',
  );
  final shakes = knobs.int.slider(
    label: '칠하려 한 횟수',
    description: '넓은 화면에서 로그인 전에 시간표를 칠하려 하면 이 상자가 떤다. 값을 바꿀 때마다 한 번 떤다',
    max: 5,
  );
  return SampleProviderScope(
    // 노브를 바꾸면 폼을 처음부터 다시 연다
    key: ValueKey((guests, guestOpen, turnstile)),
    overrides: [
      usageAnalyticsProvider.overrideWithValue(const _NoUsageAnalytics()),
      turnstileFactoryProvider.overrideWithValue(
        () => SampleTurnstile(turnstile),
      ),
      guestsApiProvider.overrideWithValue(const _SampleGuests()),
      authProvider.overrideWith(_SampleAuth.new),
      kratosClientProvider.overrideWithValue(_SigningInKratos()),
      analyticsConsentProvider.overrideWith(_SampleConsent.new),
      openLinkProvider.overrideWithValue((_) async {}),
    ],
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      // 넓은 화면의 오른쪽 칸 맨 위, 380 폭이다
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _Panel(guests: guests, guestOpen: guestOpen, shakes: shakes),
        ),
      ),
    ),
  );
}

/// 'Guest'로 폼을 열고 닫기로 돌아가도록 펼침 상태를 여기서 가진다
class _Panel extends StatefulWidget {
  const _Panel({
    required this.guests,
    required this.guestOpen,
    required this.shakes,
  });

  final bool guests;
  final bool guestOpen;
  final int shakes;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  late var _open = widget.guestOpen;

  @override
  Widget build(BuildContext context) {
    final guests = widget.guests;
    return MeetingLoginPanel(
      shakes: widget.shakes,
      onLogin: () {},
      onGuest: guests ? () => setState(() => _open = true) : null,
      guestForm: guests && _open
          ? const MeetingGuestForm(meetingId: 'meeting-1')
          : null,
      onCloseGuest: () => setState(() => _open = false),
    );
  }
}

class _NoUsageAnalytics implements UsageAnalytics {
  const _NoUsageAnalytics();

  @override
  void event(UsageEvent event) {}

  @override
  void tag(UsageTag tag) {}
}

/// '모모'만 이미 참여한 닉네임으로 찾는다
class _SampleGuests implements GuestsClient {
  const _SampleGuests();

  @override
  Future<GuestLookupRead> lookupGuestV1GuestsLookupPost({
    required GuestLookup body,
    options,
  }) async {
    // 찾는 동안 닉네임 칸 끝에 도는 표시가 보이게 잠깐 기다린다
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return GuestLookupRead(
      handle: body.name == '모모' ? 'guest-momo' : null,
      consentVersion: '2026-11-01',
    );
  }

  @override
  Future<GuestRead> createGuestV1GuestsPost({
    required GuestCreate body,
    options,
  }) async => GuestRead(
    guestId: 'guest-1',
    handle: 'guest-new',
    resourceType: body.resourceType,
    resourceId: body.resourceId,
  );

  @override
  Future<void> deleteMeV1GuestsMeDelete({options}) async {}

  @override
  Future<void> putMyConsentV1GuestsMeConsentPut({
    required ConsentCreate body,
    options,
  }) async {}
}

class _SampleAuth extends AuthNotifier {
  @override
  AuthStatus build() => const AuthStatus.unauthenticated();
}

/// 앱은 들어가면 모임 화면이 게스트 화면으로 바뀐다. 카탈로그에는 그 화면이 없어 들어가는 중에서 멈춘다
class _SigningInKratos implements KratosClient {
  @override
  Future<KratosFlow> createFlow(
    KratosFlowType type, {
    String? sessionToken,
    String? returnTo,
  }) => Completer<KratosFlow>().future;

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('카탈로그에서는 로그인 흐름을 만들기만 한다');
}

class _SampleConsent extends AnalyticsConsentNotifier {
  @override
  AnalyticsConsent? build() => null;
}
