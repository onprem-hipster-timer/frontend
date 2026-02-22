// WebSocket 타이머 API — 파서 및 모델 re-export
//
// 모델은 [models/]에 분리. 상세 스펙: API 문서 WebSocket 섹션 참고.

import 'dart:convert';

import 'package:momeet/shared/api/ws/models/export.dart';

export 'package:momeet/shared/api/ws/models/export.dart';

/// 서버에서 받은 JSON 문자열을 [TimerWsEvent]로 파싱
TimerWsEvent parseTimerWsMessage(String raw) {
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final type = map['type'] as String? ?? '';
    final payload = map['payload'] as Map<String, dynamic>? ?? {};
    final fromUser = map['from_user'] as String?;

    final payloadJson = Map<String, Object?>.from(payload);

    switch (type) {
      case 'connected':
        final connectedPayload = {
          ...payloadJson,
          'user_id': payloadJson['user_id'] ?? fromUser ?? '',
          'message': payloadJson['message'] ?? 'Connected to timer WebSocket',
        };
        return TimerWsConnected.fromJson(connectedPayload);
      case 'timer.created':
        return TimerWsTimerCreated.fromJson(payloadJson);
      case 'timer.updated':
        return TimerWsTimerUpdated.fromJson(payloadJson);
      case 'timer.completed':
        return TimerWsTimerCompleted.fromJson(payloadJson);
      case 'timer.sync_result':
      case 'timer.synced':
        return TimerWsSyncResult.fromJson(payloadJson);
      case 'timer.friend_activity':
        return TimerWsFriendActivity.fromJson(payloadJson);
      case 'error':
        return TimerWsError.fromJson({
          'code': payloadJson['code'] ?? 'UNKNOWN',
          'message': payloadJson['message'] ?? '',
        });
      default:
        return TimerWsUnknown(rawType: type, payload: payload);
    }
  } catch (_) {
    return TimerWsUnknown(rawType: '', payload: null);
  }
}
