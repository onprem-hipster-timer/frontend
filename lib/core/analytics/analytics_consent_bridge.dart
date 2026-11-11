import 'package:momeet/core/analytics/analytics_consent.dart';

/// 웹이 아니면 메모리에만 둔다
AnalyticsConsentBridge createAnalyticsConsentBridge() =>
    InMemoryAnalyticsConsentBridge();
