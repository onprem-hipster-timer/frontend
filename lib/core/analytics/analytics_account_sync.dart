// 회원 계정의 사용성 분석 동의와 이 브라우저의 동의를 맞춘다

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';

part 'analytics_account_sync.g.dart';

/// 회원으로 로그인한 동안은 계정의 사용성 분석 동의(프로필의 `analytics_consent`, 지금 약관 버전의 동의 기록)가
/// 기준이다. 앱이 켜져 있는 동안 늘 듣는다(`MoMeetApp`).
///
/// - 계정에 값이 있으면 이 브라우저에 맞춘다(허용이면 Clarity를 불러오고, 거부면 멈춘다).
/// - 계정에 값이 없고 이 브라우저에 고른 값이 있으면 그 값을 계정에 한 번 보낸다(로그인마다 한 번, 실패해도
///   다시 보내지 않는다).
/// - 둘 다 없으면 모으지 않는다. 회원에게는 처음 방문 배너를 보이지 않는다(마이페이지에서 켤 수 있다).
/// - 바뀐 약관에 아직 동의하지 않았으면 계정 값을 읽지도 보내지도 않는다(동의 화면이 함께 보낸다).
///
/// 게스트와 로그인하지 않은 방문자는 이 브라우저 값만 쓰고, 아직 고르지 않았으면 배너를 보인다. 로그아웃해도
/// 마지막으로 맞춘 값은 브라우저에 그대로 둔다.
///
/// 테스트: test/core/analytics/analytics_account_sync_test.dart
@Riverpod(keepAlive: true)
void analyticsAccountSync(Ref ref) {
  // 브라우저 값을 계정에 보낸 회원(한 번만 보낸다)
  final sent = <String>{};

  void apply() {
    final auth = ref.read(authProvider);
    final bridge = ref.read(analyticsConsentBridgeProvider);
    final browser = ref.read(analyticsConsentProvider);
    if (auth is AuthLoading) return;
    if (auth is! AuthAuthenticated) {
      bridge.showBanner(browser == null);
      return;
    }
    bridge.showBanner(false);
    final profile = ref.read(myProfileProvider).value;
    if (profile == null || profile.consentRequired) return;
    final account = profile.analyticsConsent;
    if (account != null) {
      final value = AnalyticsConsent.of(account);
      if (browser != value) {
        ref.read(analyticsConsentProvider.notifier).set(value);
      }
      return;
    }
    if (browser == null || !sent.add(profile.id)) return;
    unawaited(
      ref
          .read(myProfileProvider.notifier)
          .setAnalytics(browser == AnalyticsConsent.granted)
          .then<void>((_) {}, onError: (_) {}),
    );
  }

  ref
    ..listen(authProvider, (_, _) => apply())
    ..listen(myProfileProvider, (_, _) => apply(), fireImmediately: true);
}
