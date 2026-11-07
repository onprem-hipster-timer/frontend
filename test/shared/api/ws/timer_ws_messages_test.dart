import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/rest/models/timer_status.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

void main() {
  // ============================================================
  // parseTimerWsMessage — 서버 → 클라이언트 봉투 파싱
  // ============================================================
  group('parseTimerWsMessage', () {
    test('connected를 파싱한다', () {
      final raw = jsonEncode({
        'id': 'm0',
        'type': 'connected',
        'from_user': null,
        'timestamp': '2026-11-06T10:30:00+0000',
        'payload': {},
      });

      expect(parseTimerWsMessage(raw), isA<TimerWsConnected>());
    });

    test('timer.updated의 봉투와 payload를 파싱한다', () {
      final raw = jsonEncode(
        _envelope(
          'timer.updated',
          id: 'm1',
          fromUser: 'user-1',
          action: 'pause',
          actorName: '홍길동',
          timer: _timerJson('t1', status: 'PAUSED'),
        ),
      );

      final event = parseTimerWsMessage(raw) as TimerWsTimerEvent;
      expect(event.id, 'm1');
      expect(event.type, 'timer.updated');
      expect(event.fromUser, 'user-1');
      expect(event.payload.action, 'pause');
      expect(event.payload.actorName, '홍길동');
      expect(event.payload.timer!.id, 't1');
      expect(event.payload.timer!.status, TimerStatus.paused);
      expect(event.payload.timer!.ownerId, 'user-1');
    });

    test('timer.created를 파싱한다', () {
      final raw = jsonEncode(
        _envelope('timer.created', action: 'start', timer: _timerJson('t1')),
      );

      final event = parseTimerWsMessage(raw) as TimerWsTimerEvent;
      expect(event.type, 'timer.created');
      expect(event.payload.timer!.status, TimerStatus.running);
    });

    test('timer.deleted는 timer가 null이고 timer_id로 식별한다', () {
      final raw = jsonEncode(
        _envelope('timer.deleted', action: 'delete', timerId: 't1'),
      );

      final event = parseTimerWsMessage(raw) as TimerWsTimerEvent;
      expect(event.payload.timer, isNull);
      expect(event.payload.timerId, 't1');
    });

    test('actor_name이 null이어도 파싱한다', () {
      final raw = jsonEncode(
        _envelope('timer.updated', action: 'resume', timer: _timerJson('t1')),
      );

      final event = parseTimerWsMessage(raw) as TimerWsTimerEvent;
      expect(event.payload.actorName, isNull);
    });

    test('콜론 없는 오프셋(+0000) 시각을 UTC 같은 시각으로 파싱한다', () {
      final raw = jsonEncode(
        _envelope(
          'timer.updated',
          action: 'pause',
          timer: _timerJson('t1', updatedAt: '2026-11-06T10:30:00+0000'),
        ),
      );

      final event = parseTimerWsMessage(raw) as TimerWsTimerEvent;
      expect(event.timestamp, DateTime.utc(2026, 11, 6, 10, 30));
      expect(event.payload.timer!.updatedAt, DateTime.utc(2026, 11, 6, 10, 30));
      expect(event.payload.timer!.updatedAt.isUtc, isTrue);
    });

    group('봉투가 아니면 null', () {
      test('pong', () => expect(parseTimerWsMessage('pong'), isNull));

      test('JSON이 아닌 문자열', () {
        expect(parseTimerWsMessage('not-json-at-all'), isNull);
      });

      test('빈 문자열', () => expect(parseTimerWsMessage(''), isNull));

      test('객체가 아닌 JSON', () => expect(parseTimerWsMessage('[1]'), isNull));

      test('모르는 type', () {
        final raw = jsonEncode(_envelope('timer.sync_result', action: 'x'));
        expect(parseTimerWsMessage(raw), isNull);
      });

      test('type이 없음', () {
        expect(parseTimerWsMessage(jsonEncode({'payload': {}})), isNull);
      });
    });
  });
}

// ============================================================
// Helper — 서버 봉투 / TimerData JSON
// ============================================================

Map<String, Object?> _envelope(
  String type, {
  String id = 'msg-1',
  String? fromUser = 'user-1',
  required String action,
  String? actorName,
  Map<String, Object?>? timer,
  String? timerId,
}) {
  return {
    'id': id,
    'type': type,
    'from_user': fromUser,
    'timestamp': '2026-11-06T10:30:00+0000',
    'payload': {
      'action': action,
      'actor_name': actorName,
      'timer': timer,
      'timer_id': ?timerId,
    },
  };
}

Map<String, Object?> _timerJson(
  String id, {
  String status = 'RUNNING',
  String updatedAt = '2026-11-06T10:00:00+0000',
}) {
  return {
    'id': id,
    'schedule_id': null,
    'todo_id': null,
    'title': '작업',
    'description': null,
    'allocated_duration': 3600,
    'elapsed_time': 0,
    'status': status,
    'started_at': '2026-11-06T10:00:00+0000',
    'paused_at': null,
    'ended_at': null,
    'pause_history': [
      {'action': 'start', 'at': '2026-11-06T10:00:00+0000'},
    ],
    'created_at': '2026-11-06T10:00:00+0000',
    'updated_at': updatedAt,
    'owner_id': 'user-1',
  };
}
