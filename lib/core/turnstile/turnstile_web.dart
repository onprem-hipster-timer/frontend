import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';

/// 웹: 사이트 키가 있으면 Cloudflare Turnstile 위젯을 쓴다
TurnstileController Function()? turnstileFactory(String? siteKey) =>
    siteKey == null ? null : () => _WebTurnstile(siteKey);

/// 명시적 렌더링(`render=explicit`)으로 불러와, 위젯은 [_WebTurnstile]이 정한 칸에만 그린다
const _scriptUrl =
    'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';

/// 스크립트를 불러오다 멈춘 것으로 보는 시간
const _loadTimeout = Duration(seconds: 20);

@JS('turnstile')
external _TurnstileApi? get _api;

@JS('document')
external _Document get _document;

extension type _TurnstileApi._(JSObject _) implements JSObject {
  external JSString render(JSObject container, JSObject options);
  external void reset(JSString widgetId);
  external void remove(JSString widgetId);
}

extension type _Document._(JSObject _) implements JSObject {
  external _Element createElement(String tag);
  external _Element get head;
}

extension type _Element._(JSObject _) implements JSObject {
  external void setAttribute(String name, String value);
  external void appendChild(JSObject child);
  external void addEventListener(String type, JSFunction listener);
  external _Style get style;
}

extension type _Style._(JSObject _) implements JSObject {
  external set width(String value);
  external set height(String value);
}

Future<_TurnstileApi>? _loading;

/// Cloudflare 스크립트를 한 페이지에서 한 번만 불러온다. 실패하면 다음 부름에서 다시 불러온다
Future<_TurnstileApi> _loadApi() =>
    _loading ??= _inject().catchError((Object error) {
      _loading = null;
      throw error;
    });

Future<_TurnstileApi> _inject() {
  final loaded = _api;
  if (loaded != null) return Future.value(loaded);
  final done = Completer<_TurnstileApi>();
  void fail() {
    if (!done.isCompleted) {
      done.completeError(const TurnstileException(TurnstileStatus.unavailable));
    }
  }

  final script = _document.createElement('script')
    ..setAttribute('src', _scriptUrl)
    ..setAttribute('async', '');
  script
    ..addEventListener(
      'load',
      ((JSAny? _) {
        final api = _api;
        if (api == null) return fail();
        if (!done.isCompleted) done.complete(api);
      }).toJS,
    )
    ..addEventListener('error', ((JSAny? _) => fail()).toJS);
  _document.head.appendChild(script);
  return done.future.timeout(
    _loadTimeout,
    onTimeout: () =>
        throw const TurnstileException(TurnstileStatus.unavailable),
  );
}

/// 위젯의 크기와 색. 칸이 300보다 좁으면 compact(150×140), 아니면 normal(300×65)이다
typedef _Look = ({String size, String theme});

class _WebTurnstile implements TurnstileController {
  _WebTurnstile(this._siteKey);

  final String _siteKey;

  @override
  final ValueNotifier<TurnstileStatus> status = ValueNotifier(
    TurnstileStatus.verifying,
  );

  _Element? _container;
  _Look? _look;
  String? _widgetId;
  String? _token;
  final _waiters = <Completer<String>>[];
  var _disposed = false;

  @override
  Widget buildBox(BuildContext context) => _TurnstileView(owner: this);

  @override
  Future<String> nextToken() {
    if (_disposed) {
      return Future.error(
        const TurnstileException(TurnstileStatus.unavailable),
      );
    }
    final token = _token;
    if (token != null) {
      _token = null;
      return Future.value(token);
    }
    if (status.value == TurnstileStatus.unavailable) {
      return Future.error(
        const TurnstileException(TurnstileStatus.unavailable),
      );
    }
    // 확인하지 못한 채라면 다시 확인한다
    if (status.value == TurnstileStatus.failed) reset();
    final waiter = Completer<String>();
    _waiters.add(waiter);
    return waiter.future;
  }

  @override
  void reset() {
    if (_disposed) return;
    _token = null;
    final widgetId = _widgetId;
    if (widgetId == null) {
      unawaited(_render());
      return;
    }
    status.value = TurnstileStatus.verifying;
    try {
      _api?.reset(widgetId.toJS);
    } catch (_) {
      _fail(TurnstileStatus.failed);
    }
  }

  @override
  void dispose() {
    _removeWidget();
    _fail(TurnstileStatus.unavailable);
    _disposed = true;
    status.dispose();
  }

  /// 플랫폼 뷰가 만든 칸 [container]에 위젯을 그린다. 칸이 바뀌면(크기·색) 앞의 위젯을 지우고 새로 그린다
  void _attach(_Element container, _Look look) {
    if (_disposed) return;
    _removeWidget();
    _container = container;
    _look = look;
    container.style
      ..width = '100%'
      ..height = '100%';
    unawaited(_render());
  }

  Future<void> _render() async {
    final container = _container;
    final look = _look;
    if (container == null || look == null || _widgetId != null) return;
    status.value = TurnstileStatus.verifying;
    final _TurnstileApi api;
    try {
      api = await _loadApi();
    } catch (_) {
      if (!_disposed && identical(container, _container)) {
        _fail(TurnstileStatus.unavailable);
      }
      return;
    }
    if (_disposed || !identical(container, _container) || _widgetId != null) {
      return;
    }
    final options = JSObject()
      ..['sitekey'] = _siteKey.toJS
      ..['size'] = look.size.toJS
      ..['theme'] = look.theme.toJS
      ..['language'] = 'ko'.toJS
      // 폼으로 보내지 않고 토큰만 받는다
      ..['response-field'] = false.toJS
      ..['callback'] = ((JSString token) => _onToken(token.toDart)).toJS
      ..['error-callback'] = ((JSAny? _) => _fail(TurnstileStatus.failed)).toJS
      ..['expired-callback'] = ((JSAny? _) => _onExpired()).toJS
      ..['timeout-callback'] = ((JSAny? _) => _fail(
        TurnstileStatus.failed,
      )).toJS;
    try {
      _widgetId = api.render(container, options).toDart;
    } catch (_) {
      _fail(TurnstileStatus.unavailable);
    }
  }

  void _onToken(String token) {
    if (_disposed) return;
    status.value = TurnstileStatus.ready;
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete(token);
    } else {
      _token = token;
    }
  }

  /// 쓰지 않은 토큰이 시간이 지나 버려졌다. 위젯이 저절로 새로 확인한다
  void _onExpired() {
    if (_disposed) return;
    _token = null;
    status.value = TurnstileStatus.verifying;
  }

  void _fail(TurnstileStatus failure) {
    if (_disposed) return;
    _token = null;
    status.value = failure;
    for (final waiter in _waiters) {
      waiter.completeError(TurnstileException(failure));
    }
    _waiters.clear();
  }

  void _removeWidget() {
    final widgetId = _widgetId;
    _widgetId = null;
    if (widgetId == null) return;
    try {
      _api?.remove(widgetId.toJS);
    } catch (_) {
      // 칸이 이미 없어졌으면 지울 것도 없다
    }
  }
}

/// Cloudflare 위젯을 그리는 플랫폼 뷰. 폭에 맞춰 크기를 고르고 앱의 밝기로 색을 맞춘다
class _TurnstileView extends StatelessWidget {
  const _TurnstileView({required this.owner});

  final _WebTurnstile owner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).brightness == Brightness.dark
        ? 'dark'
        : 'light';
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 300;
        final _Look look = (size: compact ? 'compact' : 'normal', theme: theme);
        return Center(
          child: SizedBox(
            width: compact ? 150 : 300,
            height: compact ? 140 : 65,
            child: HtmlElementView.fromTagName(
              key: ValueKey(look),
              tagName: 'div',
              onElementCreated: (element) =>
                  owner._attach(element as _Element, look),
            ),
          ),
        );
      },
    );
  }
}
