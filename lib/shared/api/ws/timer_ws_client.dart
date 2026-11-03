// WebSocket 타이머 API 클라이언트
//
// - 인증: Sec-WebSocket-Protocol: authorization.bearer.<jwt>
// - 재연결: 인증 실패(1008)·의도적 종료 외 모든 끊김에 지수 백오프+지터로 무제한 재시도
// - 메시지: JSON, type + payload

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:momeet/core/config/app_config.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 타이머 WebSocket 클라이언트
///
/// 연결 후 [messageStream]으로 서버 이벤트를 구독하고,
/// [createTimer], [pauseTimer], [resumeTimer], [stopTimer], [syncTimers]로 제어합니다.
class TimerWsClient {
  TimerWsClient({
    required String accessToken,
    String? timezone,
    @visibleForTesting bool autoConnect = true,
    @visibleForTesting
    WebSocketChannel Function(Uri uri, Iterable<String> protocols)?
    connectChannel,
    @visibleForTesting Random? random,
  }) : _token = accessToken,
       _timezone = timezone,
       _connectChannel = connectChannel ?? _defaultConnect,
       _random = random ?? Random() {
    if (autoConnect) _connect();
  }

  final String _token;
  final String? _timezone;
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

  @visibleForTesting
  String get token => _token;

  /// Sec-WebSocket-Protocol 헤더에 사용되는 인증 서브프로토콜 목록
  @visibleForTesting
  static List<String> authProtocols(String token) => [
    'authorization.bearer.$token',
  ];

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _messageController = StreamController<TimerWsEvent>.broadcast();
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _manualClose = false;

  /// 서버에서 오는 이벤트 스트림
  Stream<TimerWsEvent> get messageStream => _messageController.stream;

  /// 연결이 열려 있는지
  bool get isConnected =>
      _channel != null &&
      _channel!.closeCode == null &&
      _channel!.closeReason == null;

  /// WebSocket URL 생성 (apiBaseUrl 기반)
  ///
  /// 예: https://api.momeet.date → wss://api.momeet.date/v1/ws/timers
  static String wsUrl(String baseUrl, {String? timezone}) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    const path = '/v1/ws/timers';
    var url = '$scheme://$host$port$path';
    if (timezone != null && timezone.isNotEmpty) {
      url += '?timezone=${Uri.encodeComponent(timezone)}';
    }
    return url;
  }

  void _connect() {
    if (_disposed || _manualClose) return;

    final url = wsUrl(AppConfig.apiBaseUrl, timezone: _timezone);
    final uri = Uri.parse(url);
    final protocols = authProtocols(_token);

    if (kDebugMode && AppConfig.enableDebugLogging) {
      debugPrint('🔌 [WS] Connecting to $url');
    }

    _channel = _connectChannel(uri, protocols);

    _subscription = _channel!.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  void _onData(dynamic data) {
    if (_disposed) return;
    final raw = data is String
        ? data
        : (data is List<int> ? utf8.decode(data) : data.toString());
    try {
      final event = parseTimerWsMessage(raw);
      // 서버가 connected를 보내면 연결 성공으로 보고 백오프를 처음부터 다시 시작한다.
      // 서버는 connected 직후 활성 타이머 sync_result를 보내므로 상태 복원은 그 메시지로 된다.
      if (event is TimerWsConnected) _reconnectAttempts = 0;
      if (!_messageController.isClosed) {
        _messageController.add(event);
      }
      if (kDebugMode && AppConfig.enableDebugLogging) {
        debugPrint('📩 [WS] ${event.runtimeType}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('📩 [WS] Parse error: $e');
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

    _subscription?.cancel();
    _subscription = null;
    _channel = null;

    if (_disposed || _manualClose) return;

    // Close code별 재연결 정책
    // - 1008: 인증 실패 → 재연결 금지, 토큰 갱신 후 재시도 필요
    // - 그 외(1000, 1001, 1006, 1011, 4029, 코드 없음 등): 지수 백오프 후 재시도
    //   서버(Cloud Run)는 요청 타임아웃·인스턴스 축소·교체 때 연결을 끊으므로
    //   서버 쪽 끊김은 정상 동작으로 보고 다시 붙는다.
    //   의도적 종료(disconnect/dispose)는 위에서 이미 걸러진다.
    if (closeCode == 1008) {
      if (kDebugMode && AppConfig.enableDebugLogging) {
        debugPrint('🔒 [WS] Authentication failed (1008), not reconnecting');
      }
      if (!_messageController.isClosed) {
        _messageController.add(
          TimerWsError(
            code: 'AUTH_FAILED',
            message: 'Authentication failed - token refresh required',
          ),
        );
      }
      return;
    }

    final delay = reconnectDelay(_reconnectAttempts, _random.nextDouble());
    _reconnectAttempts++;
    if (kDebugMode && AppConfig.enableDebugLogging) {
      debugPrint(
        '🔌 [WS] Reconnecting in ${delay.inMilliseconds}ms (close code: $closeCode, attempt $_reconnectAttempts)',
      );
    }
    _reconnectTimer = Timer(delay, _connect);
  }

  void _send(String type, Map<String, dynamic> payload) {
    if (!isConnected || _channel == null) {
      if (kDebugMode) debugPrint('⚠️ [WS] Not connected, cannot send $type');
      return;
    }
    final msg = jsonEncode({'type': type, 'payload': payload});
    _channel!.sink.add(msg);
    if (kDebugMode && AppConfig.enableDebugLogging) {
      debugPrint('📤 [WS] Sent $type');
    }
  }

  /// 타이머 생성 및 시작
  ///
  /// [allocatedDuration]은 서버에서 필수(양수, 초 단위)입니다.
  void createTimer({
    required int allocatedDuration,
    String? title,
    String? description,
    String? scheduleId,
    String? todoId,
    List<String>? tagIds,
  }) {
    final payload = TimerCreatePayload(
      allocatedDuration: allocatedDuration,
      title: title,
      description: description,
      scheduleId: scheduleId,
      todoId: todoId,
      tagIds: tagIds,
    );
    _send('timer.create', payload.toJson());
  }

  /// 타이머 일시정지
  void pauseTimer(String timerId) {
    _send('timer.pause', TimerIdPayload(timerId: timerId).toJson());
  }

  /// 타이머 재개
  void resumeTimer(String timerId) {
    _send('timer.resume', TimerIdPayload(timerId: timerId).toJson());
  }

  /// 타이머 중지
  void stopTimer(String timerId) {
    _send('timer.stop', TimerIdPayload(timerId: timerId).toJson());
  }

  /// 활성 타이머 동기화 요청
  void syncTimers({String? timerId, String scope = 'active'}) {
    _send(
      'timer.sync',
      TimerSyncPayload(timerId: timerId, scope: scope).toJson(),
    );
  }

  /// 연결 종료 (재연결하지 않음)
  void disconnect() {
    _manualClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 리소스 해제
  void dispose() {
    _disposed = true;
    _manualClose = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _messageController.close();
  }
}
