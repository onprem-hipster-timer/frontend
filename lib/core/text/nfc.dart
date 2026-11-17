// 유니코드 NFC 정규화. Dart에는 정규화가 없어 웹에서는 브라우저의 String.prototype.normalize를 쓴다.

export 'package:momeet/core/text/nfc_stub.dart'
    if (dart.library.js_interop) 'package:momeet/core/text/nfc_web.dart';
