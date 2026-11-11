import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/core/analytics/analytics_consent.dart';

void main() {
  group('AnalyticsConsent.parse', () {
    test('granted·denied만 읽고 나머지는 고르지 않은 것으로 본다', () {
      expect(AnalyticsConsent.parse('granted'), AnalyticsConsent.granted);
      expect(AnalyticsConsent.parse('denied'), AnalyticsConsent.denied);
      expect(AnalyticsConsent.parse(null), isNull);
      expect(AnalyticsConsent.parse(''), isNull);
      expect(AnalyticsConsent.parse('GRANTED'), isNull);
    });
  });

  group('analyticsConsentProvider', () {
    ProviderContainer containerWith(AnalyticsConsentBridge bridge) {
      final container = ProviderContainer(
        overrides: [analyticsConsentBridgeProvider.overrideWithValue(bridge)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('저장된 값으로 시작한다', () {
      final granted = containerWith(
        InMemoryAnalyticsConsentBridge(AnalyticsConsent.granted),
      );
      final unset = containerWith(InMemoryAnalyticsConsentBridge());

      expect(granted.read(analyticsConsentProvider), AnalyticsConsent.granted);
      expect(unset.read(analyticsConsentProvider), isNull);
    });

    test('set은 저장소에 쓰고 바로 상태를 바꾼다', () {
      final bridge = InMemoryAnalyticsConsentBridge(AnalyticsConsent.granted);
      final container = containerWith(bridge);

      container
          .read(analyticsConsentProvider.notifier)
          .set(AnalyticsConsent.denied);

      expect(bridge.current, AnalyticsConsent.denied);
      expect(container.read(analyticsConsentProvider), AnalyticsConsent.denied);
    });

    test('앱 밖(동의 배너)에서 바뀐 값도 따라간다', () async {
      final bridge = InMemoryAnalyticsConsentBridge();
      final container = containerWith(bridge);
      container.listen(analyticsConsentProvider, (_, _) {});

      bridge.update(AnalyticsConsent.granted);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(analyticsConsentProvider),
        AnalyticsConsent.granted,
      );
    });
  });
}
