// 사용성 분석(Microsoft Clarity) 동의
//
// 웹에서는 web/index.html의 `window.__momeetAnalytics`가 동의를 저장하고 Clarity를 불러온다.
// 앱은 그 값을 읽고 바꾸기만 한다. 웹이 아니면(테스트 포함) 메모리에만 둔다.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:momeet/core/analytics/analytics_consent_bridge.dart'
    if (dart.library.js_interop) 'package:momeet/core/analytics/analytics_consent_bridge_web.dart';

part 'analytics_consent.g.dart';

/// 사용성 분석 동의 값
enum AnalyticsConsent {
  granted,
  denied;

  /// `'granted'`·`'denied'`가 아니면 null(아직 고르지 않음)
  static AnalyticsConsent? parse(String? value) => switch (value) {
    'granted' => granted,
    'denied' => denied,
    _ => null,
  };
}

/// 동의를 저장하는 곳
abstract interface class AnalyticsConsentBridge {
  /// 저장된 값. 아직 고르지 않았으면 null
  AnalyticsConsent? get current;

  /// 값을 저장한다. [changes]로도 알린다.
  void update(AnalyticsConsent value);

  /// 값이 바뀔 때마다(앱 밖의 동의 배너에서 고른 것도) 새 값
  Stream<AnalyticsConsent?> get changes;
}

/// 메모리에만 두는 [AnalyticsConsentBridge]. 웹이 아닐 때 쓴다.
class InMemoryAnalyticsConsentBridge implements AnalyticsConsentBridge {
  InMemoryAnalyticsConsentBridge([this._value]);

  AnalyticsConsent? _value;
  final _changes = StreamController<AnalyticsConsent?>.broadcast();

  @override
  AnalyticsConsent? get current => _value;

  @override
  void update(AnalyticsConsent value) {
    _value = value;
    _changes.add(value);
  }

  @override
  Stream<AnalyticsConsent?> get changes => _changes.stream;
}

/// 실행 환경의 [AnalyticsConsentBridge]. 테스트에서 덮어쓴다.
@Riverpod(keepAlive: true)
AnalyticsConsentBridge analyticsConsentBridge(Ref ref) =>
    createAnalyticsConsentBridge();

/// 사용성 분석 동의. 아직 고르지 않았으면 null
@Riverpod(keepAlive: true)
class AnalyticsConsentNotifier extends _$AnalyticsConsentNotifier {
  @override
  AnalyticsConsent? build() {
    final bridge = ref.watch(analyticsConsentBridgeProvider);
    final subscription = bridge.changes.listen((value) => state = value);
    ref.onDispose(subscription.cancel);
    return bridge.current;
  }

  void set(AnalyticsConsent value) {
    ref.read(analyticsConsentBridgeProvider).update(value);
    state = value;
  }
}
