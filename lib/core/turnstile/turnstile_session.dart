import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:momeet/core/turnstile/turnstile.dart';

/// Cloudflare Turnstile 위젯 하나의 상태와 토큰. 웹 위젯(turnstile_web.dart)이 위젯의 콜백을 그대로 넘긴다.
///
/// 위젯 설정은 `retry: auto`, `refresh-expired: auto`, `refresh-timeout: auto`라서 위젯이 스스로 다시
/// 확인한다. 그동안은 확인 중이고 기다리는 요청을 끝내지 않는다. 다시 해도 안 되는 오류와 지원하지 않는
/// 브라우저만 쓸 수 없음이 된다. 토큰은 한 번만 주고, 받은 지 [tokenLifetime]이 다 되어 가는 토큰은 주지 않는다.
///
/// 테스트: test/core/turnstile/turnstile_session_test.dart
class TurnstileSession {
  TurnstileSession({
    required void Function() resetWidget,
    DateTime Function()? now,
  }) : _resetWidget = resetWidget,
       _now = now ?? DateTime.now;

  /// Cloudflare 토큰의 수명
  static const tokenLifetime = Duration(seconds: 300);

  /// 이만큼 남았으면 이미 만료된 것으로 본다(요청이 서버에 닿는 동안 만료되지 않게)
  static const expiryMargin = Duration(seconds: 30);

  /// 다시 해도 안 되는 오류 코드(Cloudflare 오류 코드 표의 Retry: No). 그 밖의 코드는 위젯이 다시 시도한다
  static const _finalErrors = {
    '110100',
    '110110',
    '110200',
    '200100',
    '400020',
    '400021',
    '400070',
  };

  final void Function() _resetWidget;
  final DateTime Function() _now;

  final ValueNotifier<TurnstileStatus> status = ValueNotifier(
    TurnstileStatus.verifying,
  );

  String? _token;
  DateTime? _tokenAt;
  final _waiters = <Completer<String>>[];
  var _disposed = false;

  /// 아직 쓰지 않은 토큰. 없으면 위젯이 줄 때까지 기다린다
  Future<String> nextToken() {
    if (_disposed) {
      return Future.error(
        const TurnstileException(TurnstileStatus.unavailable),
      );
    }
    final token = _token;
    final at = _tokenAt;
    _token = null;
    _tokenAt = null;
    if (token != null && at != null) {
      if (_now().difference(at) < tokenLifetime - expiryMargin) {
        return Future.value(token);
      }
      // 만료 알림을 놓쳤어도(뒤로 간 탭 등) 오래된 토큰은 버리고 새로 받는다
      reset();
    }
    switch (status.value) {
      case TurnstileStatus.unavailable:
        return Future.error(
          const TurnstileException(TurnstileStatus.unavailable),
        );
      case TurnstileStatus.failed:
        reset();
      case _:
    }
    final waiter = Completer<String>();
    _waiters.add(waiter);
    return waiter.future;
  }

  /// 들고 있던 토큰을 버리고 위젯이 새로 확인하게 한다
  void reset() {
    if (_disposed) return;
    _token = null;
    _tokenAt = null;
    status.value = TurnstileStatus.verifying;
    _resetWidget();
  }

  /// callback: 확인을 마치고 토큰을 받았다
  void onToken(String token) {
    if (_disposed) return;
    status.value = TurnstileStatus.ready;
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete(token);
    } else {
      _token = token;
      _tokenAt = _now();
    }
  }

  /// expired-callback: 쓰지 않은 토큰이 만료됐다. 위젯이 스스로 새 토큰을 받는다(refresh-expired: auto)
  void onExpired() {
    if (_disposed) return;
    _token = null;
    _tokenAt = null;
    status.value = TurnstileStatus.verifying;
  }

  /// timeout-callback: 상자 안의 일을 시간 안에 마치지 못했다. 위젯이 스스로 다시 시작한다(refresh-timeout: auto)
  void onTimeout() {
    if (_disposed) return;
    status.value = TurnstileStatus.verifying;
  }

  /// error-callback: 오류 [code]. 다시 시도하는 오류면 확인 중으로 두고, 다시 해도 안 되는 오류면 쓸 수 없음이
  /// 된다. 처리했다고 true를 돌려준다(위젯이 경고를 남기지 않는다)
  bool onError(String code) {
    if (_disposed) return true;
    if (_finalErrors.contains(code)) {
      fail(TurnstileStatus.unavailable);
    } else {
      _token = null;
      _tokenAt = null;
      status.value = TurnstileStatus.verifying;
    }
    return true;
  }

  /// unsupported-callback: 이 브라우저에서는 위젯을 쓸 수 없다
  void onUnsupported() => fail(TurnstileStatus.unavailable);

  /// before-interactive-callback: 사람이 상자 안에서 할 일이 생겼다
  void onBeforeInteractive() {
    if (_disposed) return;
    status.value = TurnstileStatus.interactive;
  }

  /// after-interactive-callback: 상자 안의 일이 끝났다. 토큰이 먼저 왔으면 확인됨에 머문다
  void onAfterInteractive() {
    if (_disposed || status.value != TurnstileStatus.interactive) return;
    status.value = TurnstileStatus.verifying;
  }

  /// [failure] 상태가 되고 기다리던 요청을 그 상태로 끝낸다
  void fail(TurnstileStatus failure) {
    if (_disposed) return;
    _token = null;
    _tokenAt = null;
    status.value = failure;
    for (final waiter in _waiters) {
      waiter.completeError(TurnstileException(failure));
    }
    _waiters.clear();
  }

  void dispose() {
    fail(TurnstileStatus.unavailable);
    _disposed = true;
    status.dispose();
  }
}
