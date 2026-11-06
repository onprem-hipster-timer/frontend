import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/rest/models/timer_status.dart';
import 'package:momeet/shared/api/ws/timer_ws_messages.dart';

void main() {
  // ============================================================
  // parseTimerWsMessage — 서버 → 클라이언트 파싱
  // ============================================================
  group('parseTimerWsMessage', () {
    group('connected', () {
      test('payload의 user_id와 message를 파싱한다', () {
        final raw = jsonEncode({
          'type': 'connected',
          'payload': {
            'user_id': 'user-123',
            'message': 'Connected to timer WebSocket',
          },
        });
        final event = parseTimerWsMessage(raw) as TimerWsConnected;
        expect(event.userId, 'user-123');
        expect(event.message, 'Connected to timer WebSocket');
      });

      test('payload에 user_id 없으면 from_user로 대체한다', () {
        final raw = jsonEncode({
          'type': 'connected',
          'payload': {},
          'from_user': 'from-456',
        });
        final event = parseTimerWsMessage(raw) as TimerWsConnected;
        expect(event.userId, 'from-456');
      });

      test('payload에 message가 없으면 기본 메시지를 사용한다', () {
        final raw = jsonEncode({
          'type': 'connected',
          'payload': {'user_id': 'u1'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsConnected;
        expect(event.message, 'Connected to timer WebSocket');
      });

      test('user_id와 from_user 모두 없으면 빈 문자열이 된다', () {
        final raw = jsonEncode({'type': 'connected', 'payload': {}});
        final event = parseTimerWsMessage(raw) as TimerWsConnected;
        expect(event.userId, '');
      });
    });

    group('timer.created', () {
      test('timer와 action을 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.created',
          'payload': {'timer': _fullTimerJson('timer-1'), 'action': 'start'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerCreated;
        expect(event.timer.id, 'timer-1');
        expect(event.action, 'start');
      });

      test('action이 없으면 null이다', () {
        final raw = jsonEncode({
          'type': 'timer.created',
          'payload': {'timer': _minimalTimerJson('t1')},
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerCreated;
        expect(event.action, isNull);
      });

      test('timer의 optional 필드를 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.created',
          'payload': {'timer': _fullTimerJson('timer-full')},
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerCreated;
        expect(event.timer.title, '작업 타이머');
        expect(event.timer.description, '프로젝트 작업');
        expect(event.timer.scheduleId, 'sched-1');
        expect(event.timer.todoId, 'todo-1');
        expect(event.timer.allocatedDuration, 3600);
        expect(event.timer.elapsedTime, 120);
        expect(event.timer.startedAt, isNotNull);
      });
    });

    group('timer.updated', () {
      test('pause action으로 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.updated',
          'payload': {
            'timer': _minimalTimerJson('t2', status: 'PAUSED'),
            'action': 'pause',
          },
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerUpdated;
        expect(event.timer!.id, 't2');
        expect(event.timer!.status, TimerStatus.paused);
        expect(event.action, 'pause');
      });

      test('resume action으로 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.updated',
          'payload': {'timer': _minimalTimerJson('t3'), 'action': 'resume'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerUpdated;
        expect(event.action, 'resume');
      });

      test('sync action으로 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.updated',
          'payload': {'timer': _minimalTimerJson('t4'), 'action': 'sync'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerUpdated;
        expect(event.action, 'sync');
      });

      test('단건 조회 대상이 없으면 timer가 null이다', () {
        final raw = jsonEncode({
          'type': 'timer.updated',
          'payload': {'timer': null, 'action': 'sync'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerUpdated;
        expect(event.timer, isNull);
        expect(event.action, 'sync');
      });

      test('payload에 timer 키가 없어도 null로 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.updated',
          'payload': {'action': 'sync'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsTimerUpdated;
        expect(event.timer, isNull);
      });
    });

    group('timer.friend_activity', () {
      test('모든 필드를 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.friend_activity',
          'payload': {
            'friend_id': 'friend-1',
            'action': 'start',
            'timer_id': 'timer-99',
            'timer_title': '친구 작업',
            'display_name': '친구 이름',
          },
        });
        final event = parseTimerWsMessage(raw) as TimerWsFriendActivity;
        expect(event.friendId, 'friend-1');
        expect(event.action, 'start');
        expect(event.timerId, 'timer-99');
        expect(event.timerTitle, '친구 작업');
        expect(event.displayName, '친구 이름');
      });

      test('timer_title과 display_name이 없으면 null이다', () {
        final raw = jsonEncode({
          'type': 'timer.friend_activity',
          'payload': {'friend_id': 'f1', 'action': 'stop', 'timer_id': 't1'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsFriendActivity;
        expect(event.timerTitle, isNull);
        expect(event.displayName, isNull);
      });
    });

    group('error', () {
      test('code와 message를 파싱한다', () {
        final raw = jsonEncode({
          'type': 'error',
          'payload': {'code': 'TIMER_NOT_FOUND', 'message': '타이머를 찾을 수 없습니다'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsError;
        expect(event.code, 'TIMER_NOT_FOUND');
        expect(event.message, '타이머를 찾을 수 없습니다');
      });

      test('code가 없으면 UNKNOWN으로 채운다', () {
        final raw = jsonEncode({
          'type': 'error',
          'payload': {'message': '알 수 없는 오류'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsError;
        expect(event.code, 'UNKNOWN');
      });

      test('message가 없으면 빈 문자열로 채운다', () {
        final raw = jsonEncode({
          'type': 'error',
          'payload': {'code': 'RATE_LIMIT_EXCEEDED'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsError;
        expect(event.message, '');
      });

      test('각 에러 코드를 정상 파싱한다', () {
        for (final code in [
          'TIMER_NOT_FOUND',
          'TIMER_ALREADY_COMPLETED',
          'TIMER_NOT_RUNNING',
          'RATE_LIMIT_EXCEEDED',
          'UNAUTHORIZED',
          'PAUSE_FAILED',
        ]) {
          final raw = jsonEncode({
            'type': 'error',
            'payload': {'code': code, 'message': 'msg'},
          });
          final event = parseTimerWsMessage(raw) as TimerWsError;
          expect(event.code, code);
        }
      });
    });

    group('unknown / edge case', () {
      test('알 수 없는 type은 TimerWsUnknown으로 파싱한다', () {
        final raw = jsonEncode({
          'type': 'some.future.type',
          'payload': {'data': 123},
        });
        final event = parseTimerWsMessage(raw) as TimerWsUnknown;
        expect(event.rawType, 'some.future.type');
        expect(event.payload!['data'], 123);
      });

      test('공식 타입이 아닌 timer.completed는 TimerWsUnknown으로 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.completed',
          'payload': {'timer': _minimalTimerJson('t5', status: 'COMPLETED')},
        });
        final event = parseTimerWsMessage(raw) as TimerWsUnknown;
        expect(event.rawType, 'timer.completed');
      });

      test('공식 타입이 아닌 timer.synced는 TimerWsUnknown으로 파싱한다', () {
        final raw = jsonEncode({
          'type': 'timer.synced',
          'payload': {
            'timers': [_minimalTimerJson('t1')],
            'count': 1,
          },
        });
        final event = parseTimerWsMessage(raw) as TimerWsUnknown;
        expect(event.rawType, 'timer.synced');
      });

      test('잘못된 JSON 문자열은 TimerWsUnknown을 반환한다', () {
        final event = parseTimerWsMessage('not-json-at-all');
        expect(event, isA<TimerWsUnknown>());
        final u = event as TimerWsUnknown;
        expect(u.rawType, '');
        expect(u.payload, isNull);
      });

      test('빈 문자열은 TimerWsUnknown을 반환한다', () {
        final event = parseTimerWsMessage('');
        expect(event, isA<TimerWsUnknown>());
      });

      test('type이 없으면 TimerWsUnknown을 반환한다', () {
        final raw = jsonEncode({
          'payload': {'foo': 'bar'},
        });
        final event = parseTimerWsMessage(raw) as TimerWsUnknown;
        expect(event.rawType, '');
      });

      test('payload가 없으면 빈 맵으로 처리한다', () {
        final raw = jsonEncode({'type': 'error'});
        final event = parseTimerWsMessage(raw) as TimerWsError;
        expect(event.code, 'UNKNOWN');
        expect(event.message, '');
      });

      test('timestamp 필드가 있어도 파싱에 영향을 주지 않는다', () {
        final raw = jsonEncode({
          'type': 'error',
          'payload': {'code': 'X', 'message': 'Y'},
          'timestamp': '2026-01-28T10:00:00Z',
        });
        final event = parseTimerWsMessage(raw) as TimerWsError;
        expect(event.code, 'X');
      });
    });
  });

  // ============================================================
  // Freezed 이벤트 모델 — equality / copyWith
  // ============================================================
  group('이벤트 모델 equality', () {
    test('TimerWsConnected는 동일 값이면 같다', () {
      const a = TimerWsConnected(userId: 'u1', message: 'm');
      const b = TimerWsConnected(userId: 'u1', message: 'm');
      expect(a, b);
    });

    test('TimerWsError는 동일 값이면 같다', () {
      const a = TimerWsError(code: 'C', message: 'M');
      const b = TimerWsError(code: 'C', message: 'M');
      expect(a, b);
    });

    test('TimerWsError는 다른 값이면 다르다', () {
      const a = TimerWsError(code: 'A', message: 'M');
      const b = TimerWsError(code: 'B', message: 'M');
      expect(a, isNot(b));
    });

    test('TimerWsFriendActivity는 동일 값이면 같다', () {
      const a = TimerWsFriendActivity(
        friendId: 'f',
        action: 'a',
        timerId: 't',
        timerTitle: 'tt',
      );
      const b = TimerWsFriendActivity(
        friendId: 'f',
        action: 'a',
        timerId: 't',
        timerTitle: 'tt',
      );
      expect(a, b);
    });
  });

  group('이벤트 모델 fromJson → toJson 라운드트립', () {
    test('TimerWsConnected', () {
      final original = TimerWsConnected.fromJson({
        'user_id': 'u1',
        'message': 'hi',
      });
      final restored = TimerWsConnected.fromJson(original.toJson());
      expect(restored, original);
    });

    test('TimerWsError', () {
      final original = TimerWsError.fromJson({'code': 'ERR', 'message': 'bad'});
      final restored = TimerWsError.fromJson(original.toJson());
      expect(restored, original);
    });

    test('TimerWsFriendActivity', () {
      final original = TimerWsFriendActivity.fromJson({
        'friend_id': 'f1',
        'action': 'start',
        'timer_id': 't1',
        'timer_title': 'x',
        'display_name': 'name',
      });
      final restored = TimerWsFriendActivity.fromJson(original.toJson());
      expect(restored, original);
    });
  });
}

// ============================================================
// Helper — 최소/전체 타이머 JSON
// ============================================================

Map<String, dynamic> _minimalTimerJson(String id, {String status = 'RUNNING'}) {
  return {
    'id': id,
    'allocated_duration': 3600,
    'elapsed_time': 0,
    'status': status,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };
}

Map<String, dynamic> _fullTimerJson(String id) {
  return {
    'id': id,
    'allocated_duration': 3600,
    'elapsed_time': 120,
    'status': 'RUNNING',
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:30:00Z',
    'started_at': '2026-01-01T00:00:00Z',
    'paused_at': null,
    'ended_at': null,
    'title': '작업 타이머',
    'description': '프로젝트 작업',
    'schedule_id': 'sched-1',
    'todo_id': 'todo-1',
    'owner_id': 'owner-1',
    'is_shared': true,
    'pause_history': <dynamic>[],
    'tags': <dynamic>[],
  };
}
