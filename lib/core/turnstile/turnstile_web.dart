import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:momeet/core/turnstile/turnstile.dart';
import 'package:momeet/core/turnstile/turnstile_session.dart';

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

/// 위젯의 크기와 색. 칸이 300 이상이면 flexible(칸 폭, 높이 65), 좁으면 compact(150×140)다
typedef _Look = ({String size, String theme});

/// 게스트 단계의 위젯 이름(Cloudflare `action`: 32자까지 영문·숫자·`_`·`-`)
const _action = 'guest';

/// 위젯 크기의 기준(Cloudflare 위젯 크기)
const _minFlexibleWidth = 300.0;
const _flexibleHeight = 65.0;
const _compactSize = Size(150, 140);

class _WebTurnstile implements TurnstileController {
  _WebTurnstile(this._siteKey) {
    _session = TurnstileSession(resetWidget: _resetWidget);
  }

  final String _siteKey;
  late final TurnstileSession _session;

  @override
  ValueListenable<TurnstileStatus> get status => _session.status;

  _Element? _container;
  _Look? _look;
  String? _widgetId;
  var _disposed = false;

  @override
  Widget buildBox(BuildContext context) => _TurnstileView(owner: this);

  @override
  Future<String> nextToken() => _session.nextToken();

  @override
  void reset() => _session.reset();

  @override
  void dispose() {
    _removeWidget();
    _disposed = true;
    _session.dispose();
  }

  /// 위젯이 다시 확인하게 한다. 아직 그리지 않았으면 그린다
  void _resetWidget() {
    final widgetId = _widgetId;
    if (widgetId == null) {
      unawaited(_render());
      return;
    }
    try {
      _api?.reset(widgetId.toJS);
    } catch (_) {
      _session.fail(TurnstileStatus.unavailable);
    }
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
    final _TurnstileApi api;
    try {
      api = await _loadApi();
    } catch (_) {
      if (!_disposed && identical(container, _container)) {
        _session.fail(TurnstileStatus.unavailable);
      }
      return;
    }
    if (_disposed || !identical(container, _container) || _widgetId != null) {
      return;
    }
    final session = _session;
    final options = JSObject()
      ..['sitekey'] = _siteKey.toJS
      ..['action'] = _action.toJS
      ..['size'] = look.size.toJS
      ..['theme'] = look.theme.toJS
      ..['language'] = 'ko'.toJS
      ..['appearance'] = 'always'.toJS
      ..['execution'] = 'render'.toJS
      // 위젯이 스스로 다시 시도하고(retry), 만료·시간 초과 뒤에도 스스로 새로 확인한다
      ..['retry'] = 'auto'.toJS
      ..['refresh-expired'] = 'auto'.toJS
      ..['refresh-timeout'] = 'auto'.toJS
      // 폼으로 보내지 않고 토큰만 받는다
      ..['response-field'] = false.toJS
      ..['callback'] = ((JSString token) => session.onToken(token.toDart)).toJS
      ..['error-callback'] =
          ((JSAny? code) => session.onError('${code.dartify()}').toJS).toJS
      ..['expired-callback'] = (() => session.onExpired()).toJS
      ..['timeout-callback'] = (() => session.onTimeout()).toJS
      ..['unsupported-callback'] = (() => session.onUnsupported()).toJS
      ..['before-interactive-callback'] =
          (() => session.onBeforeInteractive()).toJS
      ..['after-interactive-callback'] =
          (() => session.onAfterInteractive()).toJS;
    try {
      _widgetId = api.render(container, options).toDart;
    } catch (_) {
      _session.fail(TurnstileStatus.unavailable);
    }
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

/// Cloudflare 위젯을 그리는 플랫폼 뷰. 폭에 맞춰 크기를 고르고 앱의 밝기로 색을 맞춘다.
///
/// 칸이 300 이상이면 flexible(칸 폭 × 65)이라 폼의 칸들과 폭이 맞고, 좁으면 compact(150 × 140)다.
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
        final compact = constraints.maxWidth < _minFlexibleWidth;
        final _Look look = (
          size: compact ? 'compact' : 'flexible',
          theme: theme,
        );
        final view = HtmlElementView.fromTagName(
          key: ValueKey(look),
          tagName: 'div',
          onElementCreated: (element) =>
              owner._attach(element as _Element, look),
        );
        return compact
            ? Center(
                child: SizedBox.fromSize(size: _compactSize, child: view),
              )
            : SizedBox(
                width: constraints.maxWidth,
                height: _flexibleHeight,
                child: view,
              );
      },
    );
  }
}
