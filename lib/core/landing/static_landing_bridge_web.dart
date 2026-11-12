import 'dart:js_interop';

/// web/landing/script.js가 연 `window.__momeet.showLanding`을 부른다. 없으면 아무것도 하지 않는다.
void showStaticLanding() => _momeet?.showLanding?.callAsFunction();

@JS('__momeet')
external _Momeet? get _momeet;

extension type _Momeet._(JSObject _) implements JSObject {
  external JSFunction? get showLanding;
}
