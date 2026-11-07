// WebSocket 타이머 API — 파서 및 모델 re-export
//
// 모델은 [models/]에 분리. 봉투 계약: backend docs/api/websocket.ko.md

import 'dart:convert';

import 'package:momeet/shared/api/ws/models/export.dart';

export 'package:momeet/shared/api/ws/models/export.dart';

/// 서버 메시지를 [TimerWsEvent]로 파싱한다. 봉투가 아니거나(`pong` 등) 모르는 type이면 null.
TimerWsEvent? parseTimerWsMessage(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;

  return switch (decoded['type']) {
    'connected' => const TimerWsConnected(),
    'timer.created' ||
    'timer.updated' ||
    'timer.deleted' => TimerWsTimerEvent.fromJson(decoded),
    _ => null,
  };
}
