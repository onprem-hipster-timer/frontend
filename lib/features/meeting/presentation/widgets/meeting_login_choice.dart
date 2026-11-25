import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/analytics/usage_analytics.dart';
import 'package:momeet/features/meeting/presentation/widgets/meeting_login_choice_view.dart';

/// 로그인할 까닭과 '로그인'·'Guest' 고르기(고른 것을 사용성 분석에 보낸다). 게스트를 받으면 게스트는 이름과 비밀번호만 있으면 되지만 로그인만큼 안전하지는 않다고 적는다
class MeetingLoginChoice extends ConsumerWidget {
  const MeetingLoginChoice({super.key, required this.onLogin, this.onGuest});

  final VoidCallback onLogin;

  /// 없으면 'Guest'가 없다
  final VoidCallback? onGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onGuest = this.onGuest;
    final analytics = ref.read(usageAnalyticsProvider);
    return MeetingLoginChoiceView(
      onLogin: () {
        analytics.event(UsageEvent.meetingLoginChosen);
        onLogin();
      },
      onGuest: onGuest == null
          ? null
          : () {
              analytics.event(UsageEvent.meetingGuestChosen);
              onGuest();
            },
    );
  }
}
