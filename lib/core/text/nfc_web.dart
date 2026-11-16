import 'dart:js_interop';

/// [text]의 NFC 정규형 (브라우저의 `String.prototype.normalize`)
String nfc(String text) => text.toJS.normalize('NFC').toDart;

extension on JSString {
  external JSString normalize(String form);
}
