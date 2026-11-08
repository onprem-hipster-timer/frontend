import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

import '../../helpers/timer_fixtures.dart';

void main() {
  group('displayElapsed 경계', () {
    final startedAt = DateTime.utc(2026, 11, 6, 10, 0, 0);

    test('now가 로컬 시각이어도 UTC started_at과 같은 절대 시각으로 계산한다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        elapsedTime: 10,
      );
      final nowLocal = startedAt.add(const Duration(seconds: 20)).toLocal();

      expect(displayElapsed(timer, nowLocal), const Duration(seconds: 30));
    });

    test('now == started_at이면 저장값만 보여 준다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        elapsedTime: 10,
      );

      expect(displayElapsed(timer, startedAt), const Duration(seconds: 10));
    });

    test('실행 구간은 초 단위로 내림한다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        elapsedTime: 0,
      );

      expect(
        displayElapsed(
          timer,
          startedAt.add(const Duration(milliseconds: 1500)),
        ),
        const Duration(seconds: 1),
      );
    });

    test('PAUSED는 started_at이 미래여도 저장값이다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.paused,
        startedAt: startedAt.add(const Duration(hours: 1)),
        elapsedTime: 42,
      );

      expect(displayElapsed(timer, startedAt), const Duration(seconds: 42));
    });
  });

  group('displayRemaining 경계', () {
    final startedAt = DateTime.utc(2026, 11, 6, 10, 0, 0);

    test('경과 시간이 allocated_duration과 같으면 0이다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        allocatedDuration: 60,
        elapsedTime: 30,
      );

      expect(
        displayRemaining(timer, startedAt.add(const Duration(seconds: 30))),
        Duration.zero,
      );
    });

    test('PAUSED에서 저장된 경과 시간이 allocated_duration을 넘어도 0이다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.paused,
        startedAt: startedAt,
        allocatedDuration: 60,
        elapsedTime: 90,
      );

      expect(displayRemaining(timer, startedAt), Duration.zero);
    });

    test('displayElapsed와 같은 초 단위 내림으로 계산해 둘의 합이 allocated_duration이다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        allocatedDuration: 1500,
        elapsedTime: 0,
      );
      final now = startedAt.add(const Duration(milliseconds: 1500));

      expect(displayRemaining(timer, now), const Duration(seconds: 1499));
      expect(
        displayRemaining(timer, now) + displayElapsed(timer, now),
        const Duration(seconds: 1500),
      );
    });
  });

  group('allocated_duration 경계', () {
    final startedAt = DateTime.utc(2026, 11, 6, 10, 0, 0);

    test(
      'PAUSED 저장값이 allocated_duration을 넘어도 표시 경과 시간은 allocated_duration이다',
      () {
        final timer = makeTimer(
          id: 't1',
          status: TimerStatus.paused,
          allocatedDuration: 60,
          elapsedTime: 90,
        );

        expect(displayElapsed(timer, startedAt), const Duration(seconds: 60));
      },
    );

    test('RUNNING은 1초 남으면 false, 정확히 다 쓰면 true', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        allocatedDuration: 60,
        elapsedTime: 0,
      );

      expect(
        isTimeUp(timer, startedAt.add(const Duration(seconds: 59))),
        isFalse,
      );
      expect(
        isTimeUp(timer, startedAt.add(const Duration(seconds: 60))),
        isTrue,
      );
    });

    test('CANCELLED면 경과 시간이 allocated_duration이어도 false', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.cancelled,
        allocatedDuration: 60,
        elapsedTime: 60,
      );

      expect(isTimeUp(timer, startedAt), isFalse);
    });
  });
}
