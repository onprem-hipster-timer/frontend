import 'dart:js_interop';

import 'package:momeet/core/share/system_share_result.dart';

/// 브라우저의 공유 창(Web Share API `navigator.share`)으로 [title]과 [url]을 보낸다. 브라우저에 없으면
/// [SystemShareResult.unavailable], 사람이 닫으면(`AbortError`) [SystemShareResult.dismissed], 그 밖에 거절되면
/// [SystemShareResult.failed]다
Future<SystemShareResult> shareWithSystem({
  required String title,
  required String url,
}) async {
  if (_navigator.share == null) return SystemShareResult.unavailable;
  try {
    await _navigator.shareData(_ShareData(title: title, url: url)).toDart;
    return SystemShareResult.shared;
  } catch (error) {
    return '$error'.contains('AbortError')
        ? SystemShareResult.dismissed
        : SystemShareResult.failed;
  }
}

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  /// 공유 함수. 지원하지 않는 브라우저면 없다
  external JSAny? get share;

  @JS('share')
  external JSPromise<JSAny?> shareData(_ShareData data);
}

extension type _ShareData._(JSObject _) implements JSObject {
  external factory _ShareData({String title, String url});
}
