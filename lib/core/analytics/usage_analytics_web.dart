import 'dart:js_interop';

import 'package:momeet/core/analytics/usage_analytics.dart';

/// 웹: Clarity가 불러와져 있으면(`window.clarity`가 있으면) 보낸다
UsageAnalytics createUsageAnalytics() => const _Clarity();

/// web/landing/analytics.js가 동의한 뒤에만 만드는 `window.clarity`
@JS('clarity')
external JSFunction? get _clarity;

class _Clarity implements UsageAnalytics {
  const _Clarity();

  @override
  void event(UsageEvent event) =>
      _clarity?.callAsFunction(null, 'event'.toJS, event.id.toJS);

  @override
  void tag(UsageTag tag) =>
      _clarity?.callAsFunction(null, 'set'.toJS, tag.key.toJS, tag.value.toJS);
}
