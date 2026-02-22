// 타이머 WebSocket 클라이언트 프로바이더
//
// - accessToken이 있을 때만 연결
// - 서버 이벤트 수신 시 activeTimer / timerHistory 무효화로 UI 동기화

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:momeet/core/providers/auth_provider.dart';
import 'package:momeet/shared/api/ws/timer_ws_client.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

import 'timer_providers.dart';

/// 타이머 WebSocket 클라이언트
///
/// 로그인된 경우에만 non-null. 토큰이 없거나 비어 있으면 null.
final timerWsClientProvider = Provider<TimerWsClient?>((ref) {
  final token = ref.watch(accessTokenProvider);
  if (token == null || token.isEmpty) return null;

  final client = TimerWsClient(accessToken: token);
  ref.onDispose(() => client.dispose());

  StreamSubscription<TimerWsEvent>? sub;
  sub = client.messageStream.listen((event) {
    switch (event) {
      case TimerWsConnected():
        client.resetReconnectAttempts();
      case TimerWsTimerCreated():
      case TimerWsTimerUpdated():
      case TimerWsTimerCompleted():
      case TimerWsSyncResult():
        ref.invalidate(activeTimerProvider);
        ref.invalidate(timerHistoryProvider);
      case TimerWsError():
        break;
      default:
        break;
    }
  });
  ref.onDispose(() => sub?.cancel());

  return client;
});
