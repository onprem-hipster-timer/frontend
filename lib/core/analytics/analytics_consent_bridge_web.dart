import 'dart:async';
import 'dart:js_interop';

import 'package:momeet/core/analytics/analytics_consent.dart';

/// web/index.html이 만든 `window.__momeetAnalytics`. 없으면 메모리에만 둔다.
AnalyticsConsentBridge createAnalyticsConsentBridge() {
  final js = _analytics;
  return js == null
      ? InMemoryAnalyticsConsentBridge()
      : _WebAnalyticsConsentBridge(js);
}

@JS('__momeetAnalytics')
external _MomeetAnalytics? get _analytics;

@JS('document')
external _EventTarget get _document;

extension type _MomeetAnalytics._(JSObject _) implements JSObject {
  external String? get();
  external void set(String value);
}

extension type _EventTarget._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
}

class _WebAnalyticsConsentBridge implements AnalyticsConsentBridge {
  _WebAnalyticsConsentBridge(this._js) {
    // index.html의 set()이 값을 바꿀 때마다 보내는 이벤트
    _document.addEventListener(
      'analytics-consent',
      ((JSAny _) => _changes.add(current)).toJS,
    );
  }

  final _MomeetAnalytics _js;
  final _changes = StreamController<AnalyticsConsent?>.broadcast();

  @override
  AnalyticsConsent? get current => AnalyticsConsent.parse(_js.get());

  @override
  void update(AnalyticsConsent value) => _js.set(value.name);

  @override
  Stream<AnalyticsConsent?> get changes => _changes.stream;
}
