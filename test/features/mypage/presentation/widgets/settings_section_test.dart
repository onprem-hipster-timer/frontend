import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';
import 'package:momeet/core/config/legal_links.dart';
import 'package:momeet/core/providers/browser_provider.dart';
import 'package:momeet/features/mypage/presentation/widgets/settings_section.dart';

import '../../../../helpers/kratos_mocks.dart';
import '../../../../helpers/pump_app.dart';

const _analytics = '사용성 분석 허용';

void main() {
  late KratosTestHarness harness;
  late List<Uri> opened;

  setUpAll(registerKratosFallbacks);

  setUp(() async {
    harness = await KratosTestHarness.create();
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
          openLinkProvider.overrideWithValue((url) async => opened.add(url)),
        ],
      ),
    );
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

    testWidgets('켜면 허용, 다시 끄면 거부로 저장한다', (tester) async {
      final bridge = InMemoryAnalyticsConsentBridge();
      await pumpSettings(tester, bridge);

      await tapText(tester, _analytics);
      expect(bridge.current, AnalyticsConsent.granted);
      expect(switchOn(tester), isTrue);

      await tapText(tester, _analytics);
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
}
