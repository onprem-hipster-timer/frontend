import 'dart:js_interop';

/// `window.__momeet.previewReady`를 [kind]로 둔다. 배포 때 랜딩의 미리보기를 찍는 쪽이 이 값을 기다린다.
/// `window.__momeet`이 없으면 만든다.
void markLandingPreviewReady(String kind) =>
    (_momeet ??= _Momeet()).previewReady = kind;

@JS('__momeet')
external _Momeet? get _momeet;

@JS('__momeet')
external set _momeet(_Momeet? value);

extension type _Momeet._(JSObject _) implements JSObject {
  _Momeet() : this._(JSObject());

  external set previewReady(String value);
}
