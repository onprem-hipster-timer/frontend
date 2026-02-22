import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

void main() {
  group('sortTimerHistory', () {
    TimerRead _timer({
      required String id,
      required String status,
      DateTime? startedAt,
      DateTime? createdAt,
    }) {
      final ca = createdAt ?? DateTime.utc(2026, 1, 1);
      return TimerRead(
        id: id,
        allocatedDuration: 3600,
        elapsedTime: 0,
        status: status,
        createdAt: ca,
        updatedAt: ca,
        startedAt: startedAt,
      );
    }

    test('활성 타이머(RUNNING/PAUSED)가 완료(COMPLETED)보다 먼저 온다', () {
      final timers = [
        _timer(id: 'c1', status: 'COMPLETED'),
        _timer(id: 'r1', status: 'RUNNING'),
        _timer(id: 'p1', status: 'PAUSED'),
      ];

      final sorted = sortTimerHistory(timers);

      // RUNNING/PAUSED가 먼저
      expect(sorted[0].status, anyOf('RUNNING', 'PAUSED'));
      expect(sorted[1].status, anyOf('RUNNING', 'PAUSED'));
      expect(sorted[2].status, 'COMPLETED');
    });

    test('같은 그룹 내에서 최신 startedAt이 먼저 온다', () {
      final timers = [
        _timer(
          id: 'r-old',
          status: 'RUNNING',
          startedAt: DateTime.utc(2026, 1, 1, 10, 0),
        ),
        _timer(
          id: 'r-new',
          status: 'RUNNING',
          startedAt: DateTime.utc(2026, 1, 1, 12, 0),
        ),
      ];

      final sorted = sortTimerHistory(timers);
      expect(sorted[0].id, 'r-new');
      expect(sorted[1].id, 'r-old');
    });

    test('startedAt이 null이면 createdAt으로 대체한다', () {
      final timers = [
        _timer(
          id: 'no-start',
          status: 'COMPLETED',
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        _timer(
          id: 'has-start',
          status: 'COMPLETED',
          startedAt: DateTime.utc(2026, 1, 1),
          createdAt: DateTime.utc(2025, 12, 31),
        ),
      ];

      final sorted = sortTimerHistory(timers);
      // no-start createdAt(1/2) > has-start startedAt(1/1)
      expect(sorted[0].id, 'no-start');
      expect(sorted[1].id, 'has-start');
    });

    test('빈 리스트는 빈 리스트를 반환한다', () {
      expect(sortTimerHistory([]), isEmpty);
    });

    test('단일 항목은 그대로 반환한다', () {
      final timers = [_timer(id: 'solo', status: 'RUNNING')];
      final sorted = sortTimerHistory(timers);
      expect(sorted.length, 1);
      expect(sorted[0].id, 'solo');
    });

    test('PAUSED와 RUNNING이 섞여있어도 모두 활성 그룹에 속한다', () {
      final timers = [
        _timer(
          id: 'p1',
          status: 'PAUSED',
          startedAt: DateTime.utc(2026, 1, 1, 8, 0),
        ),
        _timer(
          id: 'c1',
          status: 'COMPLETED',
          startedAt: DateTime.utc(2026, 1, 1, 12, 0),
        ),
        _timer(
          id: 'r1',
          status: 'RUNNING',
          startedAt: DateTime.utc(2026, 1, 1, 10, 0),
        ),
      ];

      final sorted = sortTimerHistory(timers);
      // 활성 그룹: r1(10시) > p1(8시), 완료 그룹: c1
      expect(sorted[0].id, 'r1');
      expect(sorted[1].id, 'p1');
      expect(sorted[2].id, 'c1');
    });

    test('원본 리스트를 변경하지 않는다', () {
      final timers = [
        _timer(id: 'c1', status: 'COMPLETED'),
        _timer(id: 'r1', status: 'RUNNING'),
      ];
      final originalFirst = timers[0].id;

      sortTimerHistory(timers);

      expect(timers[0].id, originalFirst);
    });

    test('완료 그룹 내에서도 최신순 정렬된다', () {
      final timers = [
        _timer(
          id: 'c-old',
          status: 'COMPLETED',
          startedAt: DateTime.utc(2026, 1, 1),
        ),
        _timer(
          id: 'c-mid',
          status: 'COMPLETED',
          startedAt: DateTime.utc(2026, 1, 5),
        ),
        _timer(
          id: 'c-new',
          status: 'COMPLETED',
          startedAt: DateTime.utc(2026, 1, 10),
        ),
      ];

      final sorted = sortTimerHistory(timers);
      expect(sorted[0].id, 'c-new');
      expect(sorted[1].id, 'c-mid');
      expect(sorted[2].id, 'c-old');
    });
  });
}
