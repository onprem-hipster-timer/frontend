import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:momeet/core/analytics/usage_analytics.dart';

/// 보낸 사용성 분석 이벤트와 태그를 차례로 모은다
class FakeUsageAnalytics implements UsageAnalytics {
  /// 보낸 것: 이벤트는 `event:<이름>`, 태그는 `tag:<키>=<값>`
  final sent = <String>[];

  List<String> get events => [
    for (final entry in sent)
      if (entry.startsWith('event:')) entry.substring(6),
  ];

  List<String> get tags => [
    for (final entry in sent)
      if (entry.startsWith('tag:')) entry.substring(4),
  ];

  @override
  void event(UsageEvent event) => sent.add('event:${event.id}');

  @override
  void tag(UsageTag tag) => sent.add('tag:${tag.key}=${tag.value}');

  Override get asOverride => usageAnalyticsProvider.overrideWithValue(this);
}

/// 보낼 수 있는 이름·값 전부. 보낸 것이 모두 이 안에 있으면 사람이 넣은 글자나 식별자가 담길 수 없다
final allowedUsageNames = {
  for (final event in UsageEvent.values) event.id,
  for (final tag in MeetingAccountTag.values) '${tag.key}=${tag.value}',
};
