import 'package:momeet/core/analytics/usage_analytics.dart';

/// 웹이 아니면 보내지 않는다
UsageAnalytics createUsageAnalytics() => const _Silent();

class _Silent implements UsageAnalytics {
  const _Silent();

  @override
  void event(UsageEvent event) {}

  @override
  void tag(UsageTag tag) {}
}
