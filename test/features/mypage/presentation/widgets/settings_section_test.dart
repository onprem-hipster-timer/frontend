import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/core/providers/my_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/shared/providers/api_providers.dart';
import 'package:momeet/features/mypage/presentation/widgets/account_deletion_dialog.dart';
import 'package:momeet/features/mypage/presentation/widgets/settings_section.dart';

import '../../../../helpers/fake_rest_clients.dart';
import '../../../../helpers/kratos_mocks.dart';
import '../../../../helpers/pump_app.dart';

const _analytics = '사용성 분석 허용';

void main() {
  late KratosTestHarness harness;
  late FakeUsersClient users;
  late List<Uri> opened;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create();
    users = FakeUsersClient(consentRequired: false);
    opened = [];
  });

  Future<void> pumpSettings(
    WidgetTester tester,
    AnalyticsConsentBridge bridge,
  ) async {
    await tester.pumpWidget(
      pumpApp(
        Scaffold(
          body: SingleChildScrollView(child: SettingsSection(onSignOut: () {})),
        ),
        overrides: [
          ...harness.overrides,
          analyticsConsentBridgeProvider.overrideWithValue(bridge),
          usersApiProvider.overrideWithValue(users),
          openLinkProvider.overrideWithValue((url) async => opened.add(url)),
        ],
      ),
    );
    // 마이페이지가 열릴 때는 앱이 이미 회원 프로필을 듣고 있다(라우터의 약관 확인)
    ProviderScope.containerOf(
      tester.element(find.byType(SettingsSection)),
    ).listen(myProfileProvider, (_, _) {});
    await tester.pumpAndSettle();
  }

  bool switchOn(WidgetTester tester) => tester
      .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, _analytics))
      .value;

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('사용성 분석 허용', () {
    for (final (stored, on) in [
      (AnalyticsConsent.granted, true),
      (AnalyticsConsent.denied, false),
      (null, false),
    ]) {
      testWidgets('저장된 값이 $stored이면 ${on ? '켜져' : '꺼져'} 있다', (tester) async {
        await pumpSettings(tester, InMemoryAnalyticsConsentBridge(stored));
        expect(switchOn(tester), on);
      });
    }

    testWidgets('무엇을 누구에게 보내는지 한 줄로 적는다', (tester) async {
      await pumpSettings(tester, InMemoryAnalyticsConsentBridge());

      expect(
        find.text('화면 개선을 위해 화면 이용 기록을 Microsoft Clarity(미국)로 보냅니다'),
        findsOneWidget,
      );
    });

    testWidgets('켜고 끄면 지금 약관 버전의 동의를 그 값과 함께 계정에 다시 보내고 이 브라우저에도 둔다', (
      tester,
    ) async {
      final bridge = InMemoryAnalyticsConsentBridge();
      await pumpSettings(tester, bridge);

      await tapText(tester, _analytics);
      expect(users.agreed.last.analytics, isTrue);
      expect(users.agreed.last.version, testConsentVersion);
      expect(users.profile.analyticsConsent, isTrue);
      expect(bridge.current, AnalyticsConsent.granted);
      expect(switchOn(tester), isTrue);

      await tapText(tester, _analytics);
      expect(users.agreed.last.analytics, isFalse);
      expect(bridge.current, AnalyticsConsent.denied);
      expect(switchOn(tester), isFalse);
      expect(users.agreed, hasLength(2), reason: '따로 부르는 요청은 없다');
    });

    testWidgets('계정에 저장하지 못하면 알리고 이 브라우저 값은 그대로다', (tester) async {
      final bridge = InMemoryAnalyticsConsentBridge(AnalyticsConsent.denied);
      await pumpSettings(tester, bridge);
      users.consentError = Exception('끊김');

      await tapText(tester, _analytics);

      expect(find.text('사용성 분석 설정을 저장하지 못했습니다'), findsOneWidget);
      expect(bridge.current, AnalyticsConsent.denied);
      expect(switchOn(tester), isFalse);
    });

    testWidgets('앱 밖(동의 배너)에서 바꾼 값을 따라간다', (tester) async {
      final bridge = InMemoryAnalyticsConsentBridge();
      await pumpSettings(tester, bridge);

      bridge.update(AnalyticsConsent.granted);
      await tester.pumpAndSettle();
      expect(switchOn(tester), isTrue);

      bridge.update(AnalyticsConsent.denied);
      await tester.pumpAndSettle();
      expect(switchOn(tester), isFalse);
    });
  });

  testWidgets('이용약관과 개인정보처리방침을 연다', (tester) async {
    await pumpSettings(tester, InMemoryAnalyticsConsentBridge());

    await tapText(tester, '이용약관');
    await tapText(tester, '개인정보처리방침');

    expect(opened, [LegalLinks.terms, LegalLinks.privacy]);
  });

  testWidgets('맨 아래 회원 탈퇴를 누르면 탈퇴 확인을 연다', (tester) async {
    await pumpSettings(tester, InMemoryAnalyticsConsentBridge());

    await tapText(tester, '회원 탈퇴');

    expect(find.byType(AccountDeletionDialog), findsOneWidget);
  });
}
