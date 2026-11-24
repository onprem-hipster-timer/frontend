import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_panel.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../sample_provider_scope.dart';
import 'samples_guest_form.dart';
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
    description: "'Guest'를 누르면 그 자리에서 게스트 폼으로 바뀐다. 폼의 닉네임·안내 상태는 '게스트 폼'에서 고른다",
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
      openLinkProvider.overrideWithValue((_) async {}),
    ],
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      // 넓은 화면의 오른쪽 칸 맨 위, 380 폭이다
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _Panel(
            guests: guests,
            guestOpen: guestOpen,
            turnstile: turnstile,
            shakes: shakes,
          ),
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
    required this.turnstile,
    required this.shakes,
  });

  final bool guests;
  final bool guestOpen;
  final TurnstileStatus turnstile;
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
          ? SampleGuestForm(turnstile: widget.turnstile)
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
