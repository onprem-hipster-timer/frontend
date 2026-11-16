// Cloudflare Turnstile 확인 위젯 (게스트 단계의 토큰)
//
// 웹에서는 Cloudflare 스크립트를 불러와 플랫폼 뷰에 위젯을 그린다(turnstile_web.dart). 웹이 아니거나
// 사이트 키가 없으면 위젯이 없고 게스트 입장을 두지 않는다. 테스트는 [turnstileFactoryProvider]를 가짜로 바꾼다.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/core/turnstile/turnstile_stub.dart'
    if (dart.library.js_interop) 'package:momeet/core/turnstile/turnstile_web.dart';

/// 확인 위젯의 상태
enum TurnstileStatus {
  /// 위젯을 불러오거나 확인하는 중
  verifying,

  /// 쓸 토큰이 있다
  ready,

  /// 확인하지 못했다. [TurnstileController.reset]으로 다시 확인한다
  failed,

  /// 위젯을 불러오지 못했다. [TurnstileController.reset]으로 다시 불러온다
  unavailable,
}

/// 확인 위젯이 토큰을 주지 못함 (확인 실패, 위젯을 불러오지 못함, 위젯을 닫음)
class TurnstileException implements Exception {
  const TurnstileException(this.status);

  final TurnstileStatus status;

  @override
  String toString() => 'TurnstileException($status)';
}

/// Cloudflare Turnstile 위젯 하나. backend가 토큰을 한 번만 받으므로 요청마다 새 토큰을 쓴다.
abstract class TurnstileController {
  /// 지금 상태
  ValueListenable<TurnstileStatus> get status;

  /// 화면에 둘 확인 상자 (Cloudflare가 그리는 위젯)
  Widget buildBox(BuildContext context);

  /// 아직 쓰지 않은 토큰. 없으면 위젯이 새 토큰을 줄 때까지 기다린다. 한 번 준 토큰은 다시 주지 않는다.
  ///
  /// 확인하지 못하거나 위젯을 닫으면 [TurnstileException]으로 끝난다.
  Future<String> nextToken();

  /// 들고 있던 토큰을 버리고 새로 확인한다. 불러오지 못했으면 다시 불러온다
  void reset();

  void dispose();
}

/// 확인 위젯을 만드는 함수. 웹에서 사이트 키가 있을 때만 있다. 없으면 게스트 입장을 두지 않는다
final turnstileFactoryProvider = Provider<TurnstileController Function()?>(
  (ref) => turnstileFactory(AppConfig.turnstileSiteKey),
);

/// 토큰 하나로 요청 하나를 보낸다
extension TurnstileRequests on TurnstileController {
  /// 새 토큰으로 [request]를 보낸다. 응답이 어떻든(거절·실패 포함) 끝나면 위젯이 다시 확인해 다음 요청은
  /// 새 토큰을 쓴다.
  Future<T> send<T>(Future<T> Function(String token) request) async {
    final token = await nextToken();
    try {
      return await request(token);
    } finally {
      reset();
    }
  }
}
