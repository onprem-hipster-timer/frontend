import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../../../helpers/timer_fixtures.dart';

void main() {
  group('sortTimerHistory', () {
    test('활성 타이머(RUNNING/PAUSED)가 완료(COMPLETED)보다 먼저 온다', () {
      final timers = [
        makeTimer(id: 'c1', status: TimerStatus.completed),
        makeTimer(id: 'r1', status: TimerStatus.running),
        makeTimer(id: 'p1', status: TimerStatus.paused),
      ];

      final sorted = sortTimerHistory(timers);

      // RUNNING/PAUSED가 먼저
      expect(sorted[0].status, anyOf(TimerStatus.running, TimerStatus.paused));
      expect(sorted[1].status, anyOf(TimerStatus.running, TimerStatus.paused));
      expect(sorted[2].status, TimerStatus.completed);
    });

    test('같은 그룹 내에서 최신 startedAt이 먼저 온다', () {
      final timers = [
        makeTimer(
          id: 'r-old',
          status: TimerStatus.running,
          startedAt: DateTime.utc(2026, 1, 1, 10, 0),
        ),
        makeTimer(
          id: 'r-new',
          status: TimerStatus.running,
          startedAt: DateTime.utc(2026, 1, 1, 12, 0),
        ),
      ];

      final sorted = sortTimerHistory(timers);
      expect(sorted[0].id, 'r-new');
      expect(sorted[1].id, 'r-old');
    });

    test('startedAt이 null이면 createdAt으로 대체한다', () {
      final timers = [
        makeTimer(
          id: 'no-start',
          status: TimerStatus.completed,
          createdAt: DateTime.utc(2026, 1, 2),
        ),
        makeTimer(
          id: 'has-start',
          status: TimerStatus.completed,
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
      final timers = [makeTimer(id: 'solo', status: TimerStatus.running)];
      final sorted = sortTimerHistory(timers);
      expect(sorted.length, 1);
      expect(sorted[0].id, 'solo');
    });

    test('PAUSED와 RUNNING이 섞여있어도 모두 활성 그룹에 속한다', () {
      final timers = [
        makeTimer(
          id: 'p1',
          status: TimerStatus.paused,
          startedAt: DateTime.utc(2026, 1, 1, 8, 0),
        ),
        makeTimer(
          id: 'c1',
          status: TimerStatus.completed,
          startedAt: DateTime.utc(2026, 1, 1, 12, 0),
        ),
        makeTimer(
          id: 'r1',
          status: TimerStatus.running,
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
        makeTimer(id: 'c1', status: TimerStatus.completed),
        makeTimer(id: 'r1', status: TimerStatus.running),
      ];
      final originalFirst = timers[0].id;

      sortTimerHistory(timers);

      expect(timers[0].id, originalFirst);
    });

    test('완료 그룹 내에서도 최신순 정렬된다', () {
      final timers = [
        makeTimer(
          id: 'c-old',
          status: TimerStatus.completed,
          startedAt: DateTime.utc(2026, 1, 1),
        ),
        makeTimer(
          id: 'c-mid',
          status: TimerStatus.completed,
          startedAt: DateTime.utc(2026, 1, 5),
        ),
        makeTimer(
          id: 'c-new',
          status: TimerStatus.completed,
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
