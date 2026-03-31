// WebSocket 타이머 API 클라이언트
//
// - 인증: Sec-WebSocket-Protocol: authorization.bearer.<jwt>
// - 재연결: Rate limit(4029) 시 지수 백오프, 최대 5회
// - 메시지: JSON, type + payload

import 'dart:async';
import 'dart:convert';

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
    this.maxReconnectAttempts = 5,
    @visibleForTesting bool autoConnect = true,
  }) : _token = accessToken,
       _timezone = timezone {
    if (autoConnect) _connect();
  }

  final String _token;
  final String? _timezone;
  final int maxReconnectAttempts;

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

    _channel = WebSocketChannel.connect(uri, protocols: protocols);

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

    // 인증 실패(4001/4003) close code인 경우 재연결하지 않음
    if (closeCode != null && (closeCode == 4001 || closeCode == 4003)) {
      if (kDebugMode && AppConfig.enableDebugLogging) {
        debugPrint(
          '🔒 [WS] Authentication failed (close code: $closeCode), not reconnecting',
        );
      }
      if (!_messageController.isClosed) {
        _messageController.add(
          TimerWsError(
            code: 'AUTH_FAILED',
            message: 'Authentication failed (close code: $closeCode)',
          ),
        );
      }
      return;
    }

    // Rate limit 4029 등으로 닫힌 경우 재연결
    if (_reconnectAttempts < maxReconnectAttempts) {
      final delay = _reconnectAttempts == 0
          ? 1000
          : (1000 * (1 << _reconnectAttempts)).clamp(1000, 60000);
      if (kDebugMode && AppConfig.enableDebugLogging) {
        debugPrint(
          '🔌 [WS] Reconnecting in ${delay}ms (attempt ${_reconnectAttempts + 1}/$maxReconnectAttempts)',
        );
      }
      Future.delayed(Duration(milliseconds: delay), () {
        _reconnectAttempts++;
        _connect();
      });
    }
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

  /// 연결 성공 시 재연결 카운트 리셋 (서버에서 connected 수신 후 호출 권장)
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
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
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  /// 리소스 해제
  void dispose() {
    _disposed = true;
    _manualClose = true;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _messageController.close();
  }
}
