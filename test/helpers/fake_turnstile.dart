import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';

/// 확인 위젯을 흉내 낸다. 실제 위젯처럼 토큰 하나를 주면 [reset]으로 다시 확인할 때까지 새 토큰이 없다.
class FakeTurnstile implements TurnstileController {
  FakeTurnstile({TurnstileStatus initial = TurnstileStatus.ready})
    : status = ValueNotifier(initial);

  @override
  final ValueNotifier<TurnstileStatus> status;

  /// 준 토큰 (준 차례)
  final issued = <String>[];

  /// 다시 확인한 횟수
  var resets = 0;

  var disposed = false;

  /// true면 다시 확인해도 [release]까지 토큰을 주지 않는다 (확인이 오래 걸리는 경우)
  var holdTokens = false;

  /// 주면 다음 [nextToken] 하나가 이 상태의 [TurnstileException]으로 끝난다
  TurnstileStatus? failNext;

  var _held = true;
  final _waiters = <Completer<String>>[];

  @override
  Widget buildBox(BuildContext context) => Semantics(
    // 실제 위젯처럼 글자가 아니라 정해진 크기의 상자다
    label: '사람인지 확인하는 상자',
    child: const SizedBox(width: 300, height: 65),
  );

  @override
  Future<String> nextToken() {
    final failure = failNext;
    if (failure != null) {
      failNext = null;
      return Future.error(TurnstileException(failure));
    }
    if (status.value == TurnstileStatus.unavailable) {
      return Future.error(
        const TurnstileException(TurnstileStatus.unavailable),
      );
    }
    if (_held && !holdTokens) return Future.value(_issue());
    final waiter = Completer<String>();
    _waiters.add(waiter);
    return waiter.future;
  }

  @override
  void reset() {
    resets++;
    _held = true;
    status.value = TurnstileStatus.ready;
    _serve();
  }

  /// 붙잡아 둔 토큰을 준다
  void release() {
    holdTokens = false;
    _serve();
  }

  @override
  void dispose() {
    disposed = true;
    for (final waiter in _waiters) {
      waiter.completeError(
        const TurnstileException(TurnstileStatus.unavailable),
      );
    }
    _waiters.clear();
  }

  void _serve() {
    if (_held && !holdTokens && _waiters.isNotEmpty) {
      _waiters.removeAt(0).complete(_issue());
    }
  }

  String _issue() {
    _held = false;
    final token = 'token-${issued.length + 1}';
    issued.add(token);
    return token;
  }
}

/// 화면이 만드는 확인 위젯을 모두 [FakeTurnstile]로 만들어 모아 둔다
class FakeTurnstiles {
  final made = <FakeTurnstile>[];

  /// 새로 만드는 위젯의 처음 상태
  var initial = TurnstileStatus.ready;

  FakeTurnstile get last => made.last;

  /// 모든 위젯이 준 토큰 (준 차례)
  List<String> get issued => [for (final fake in made) ...fake.issued];

  Override get override => turnstileFactoryProvider.overrideWithValue(_create);

  TurnstileController _create() {
    final fake = FakeTurnstile(initial: initial);
    made.add(fake);
    return fake;
  }
}
