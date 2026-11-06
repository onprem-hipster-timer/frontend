// 타이머 실시간 WebSocket 클라이언트 (수신 전용)
//
// - 주소: API_BASE_URL의 호스트 + AppConfig.realtimeWsPath (https → wss)
// - 인증: Sec-WebSocket-Protocol: authorization.bearer.<jwt>
//   (재)연결할 때마다 JWT를 새로 받는다. 끊긴 사이에 만료됐을 수 있다.
// - 서버 → 클라이언트: 이벤트 봉투(JSON). 같은 id는 한 번만 내보내고, 봉투가 아닌 메시지(pong 등)는 버린다
// - 클라이언트 → 서버: 주기적으로 문자열 ping. 명령은 REST로 보낸다
// - 닫힘 코드: 1008(인증 실패)은 JWT를 한 번 새로 받아 다시 연결하고, 또 1008이면 멈춘다.
//   4000(소켓 수명 만료)은 바로, 그 외는 지수 백오프와 지터를 두고 횟수 제한 없이 다시 연결한다
// - 앱이 포그라운드로 돌아오면 [TimerWsClient.reconnectNow]로 끊긴 연결을 바로 다시 연다
//
// 계약: backend docs/api/websocket.ko.md
// 테스트: test/shared/api/ws/timer_ws_client_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 타이머 WebSocket 클라이언트
///
/// 연결 후 [messageStream]으로 서버 이벤트를 구독합니다. 타이머 명령은 REST로 보냅니다.
class TimerWsClient {
  TimerWsClient({
    required Future<String?> Function() accessToken,
    required Future<String?> Function() refreshAccessToken,
    @visibleForTesting this.pingInterval = const Duration(seconds: 45),
    @visibleForTesting bool autoConnect = true,
    @visibleForTesting
    WebSocketChannel Function(Uri uri, Iterable<String> protocols)?
    connectChannel,
    @visibleForTesting Random? random,
  }) : _accessToken = accessToken,
       _refreshAccessToken = refreshAccessToken,
       _connectChannel = connectChannel ?? _defaultConnect,
       _random = random ?? Random() {
    if (autoConnect) _connect();
  }

  /// 연결할 때마다 부르는 JWT 공급자. null이면 로그아웃한 것이라 연결하지 않는다.
  final Future<String?> Function() _accessToken;

  /// 서버가 JWT를 거부했을 때(1008) 부르는 JWT 갱신. null이면 세션이 끝난 것이다.
  final Future<String?> Function() _refreshAccessToken;
  final Duration pingInterval;
  final WebSocketChannel Function(Uri uri, Iterable<String> protocols)
  _connectChannel;
  final Random _random;

  static WebSocketChannel _defaultConnect(
    Uri uri,
    Iterable<String> protocols,
  ) => WebSocketChannel.connect(uri, protocols: protocols);

  static const _initialReconnectDelay = Duration(seconds: 1);
  static const _maxReconnectDelay = Duration(seconds: 30);

  /// [attempt]번째(0부터) 재연결 대기 시간
  ///
  /// 1s → 2s → 4s … 상한 30s를 기준으로, [jitter](0~1)에 따라 그 50~100%를 쓴다.
  /// 여러 클라이언트가 동시에 끊겨도 재접속 시점이 흩어지게 한다.
  @visibleForTesting
  static Duration reconnectDelay(int attempt, double jitter) {
    final baseMs = min(
      _maxReconnectDelay.inMilliseconds,
      _initialReconnectDelay.inMilliseconds << min(attempt, 5),
    );
    return Duration(milliseconds: (baseMs * (0.5 + jitter / 2)).round());
  }

  /// Sec-WebSocket-Protocol 헤더에 사용되는 인증 서브프로토콜 목록
  @visibleForTesting
  static List<String> authProtocols(String token) => [
    'authorization.bearer.$token',
  ];

  /// 최근에 받은 이벤트 id를 이만큼 기억해 중복을 버린다
  static const _seenIdLimit = 1000;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  final _messageController = StreamController<TimerWsEvent>.broadcast();
  final _seenIds = <String>{};
  int _reconnectAttempts = 0;

  /// JWT를 받는 중이라 아직 채널이 없음
  bool _connecting = false;
  bool _authRetried = false;
  bool _disposed = false;
  bool _manualClose = false;

  /// 서버에서 오는 이벤트 스트림
  Stream<TimerWsEvent> get messageStream => _messageController.stream;

  /// 연결이 열려 있는지
  bool get isConnected =>
      _channel != null &&
      _channel!.closeCode == null &&
      _channel!.closeReason == null;

  /// 소켓 주소. [baseUrl]의 scheme·host·port에 [path]를 붙인다.
  ///
  /// 예: https://api.momeet.date, /v1/ws/timers → wss://api.momeet.date/v1/ws/timers
  static String wsUrl(String baseUrl, String path) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$port$path';
  }

  Future<void> _connect() async {
    if (_disposed || _manualClose || _connecting || _channel != null) return;

    _connecting = true;
    final String? token;
    try {
      token = await _accessToken();
    } catch (e) {
      // JWT를 받지 못함 (네트워크 오류 등): 연결이 끊긴 것처럼 다시 시도한다
      _onError(e);
      _reconnectWithBackoff(null);
      return;
    } finally {
      _connecting = false;
    }
    if (token == null || _disposed || _manualClose) return;

    final url = wsUrl(AppConfig.apiBaseUrl, AppConfig.realtimeWsPath);
    final uri = Uri.parse(url);
    final protocols = authProtocols(token);

    if (kDebugMode && AppConfig.enableDebugLogging) {
      debugPrint('🔌 [WS] Connecting to $url');
    }

    final channel = _channel = _connectChannel(uri, protocols);

    _subscription = channel.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
    _pingTimer = Timer.periodic(pingInterval, (_) => channel.sink.add('ping'));
  }

  void _onData(dynamic data) {
    if (_disposed) return;
    final raw = data is String
        ? data
        : (data is List<int> ? utf8.decode(data) : data.toString());
    final TimerWsEvent? event;
    try {
      event = parseTimerWsMessage(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('📩 [WS] Parse error: $e');
      return;
    }

    switch (event) {
      case null:
        return;
      case TimerWsConnected():
        _reconnectAttempts = 0;
        _authRetried = false;
      case TimerWsTimerEvent(:final id):
        if (!_seenIds.add(id)) return;
        if (_seenIds.length > _seenIdLimit) _seenIds.remove(_seenIds.first);
    }

    if (!_messageController.isClosed) {
      _messageController.add(event);
    }
    if (kDebugMode && AppConfig.enableDebugLogging) {
      debugPrint('📩 [WS] ${event.runtimeType}');
    }
  }

  void _onError(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [WS] Error: $error');
      if (stackTrace != null) debugPrint('$stackTrace');
    }
    if (!_messageController.isClosed) {
      _messageController.add(
        TimerWsError(code: 'CONNECTION_ERROR', message: error.toString()),
      );
    }
  }

  void _onDone() {
    final closeCode = _channel?.closeCode;
    _closeChannel();

    if (_disposed || _manualClose) return;

    switch (closeCode) {
      case 1008:
        _onAuthRejected();
      case 4000:
        _connect();
      default:
        _reconnectWithBackoff(closeCode);
    }
  }

  /// 1008: JWT를 한 번 새로 받아 다시 연결한다. 그래도 거부되거나 받지 못하면 멈춘다.
  Future<void> _onAuthRejected() async {
    if (!_authRetried) {
      _authRetried = true;
      String? token;
      try {
        token = await _refreshAccessToken();
      } catch (e) {
        _onError(e);
      }
      if (token != null) return _connect();
    }
    if (kDebugMode && AppConfig.enableDebugLogging) {
      debugPrint('🔒 [WS] Authentication failed (1008), not reconnecting');
    }
    if (!_messageController.isClosed) {
      _messageController.add(
        const TimerWsError(
          code: 'AUTH_FAILED',
          message: 'Authentication failed - token refresh required',
        ),
      );
    }
  }

  void _reconnectWithBackoff(int? closeCode) {
    final delay = reconnectDelay(_reconnectAttempts, _random.nextDouble());
    _reconnectAttempts++;
    if (kDebugMode && AppConfig.enableDebugLogging) {
      debugPrint(
        '🔌 [WS] Reconnecting in ${delay.inMilliseconds}ms (close code: $closeCode, attempt $_reconnectAttempts)',
      );
    }
    _reconnectTimer = Timer(delay, _connect);
  }

  /// 연결이 없으면 기다리지 않고 바로 다시 연결한다 (앱이 포그라운드로 돌아왔을 때).
  ///
  /// 연결 중이거나 [disconnect]·[dispose]한 뒤에는 아무것도 하지 않는다.
  void reconnectNow() {
    if (_disposed || _manualClose || _connecting || _channel != null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _authRetried = false;
    _connect();
  }

  void _closeChannel() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 연결 종료 (재연결하지 않음)
  void disconnect() {
    _manualClose = true;
    _reconnectTimer?.cancel();
    _closeChannel();
  }

  /// 리소스 해제
  void dispose() {
    _disposed = true;
    _manualClose = true;
    _reconnectTimer?.cancel();
    _closeChannel();
    _messageController.close();
  }
}
