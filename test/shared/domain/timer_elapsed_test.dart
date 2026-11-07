import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/timer_elapsed.dart';

import '../../helpers/timer_fixtures.dart';

void main() {
  group('displayElapsed', () {
    final startedAt = DateTime.utc(2026, 11, 6, 10, 0, 0);
    final now = DateTime.utc(2026, 11, 6, 10, 0, 30);

    test('RUNNING이면 저장값에 started_at부터 now까지를 더한다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        elapsedTime: 100,
      );

      expect(displayElapsed(timer, now), const Duration(seconds: 130));
    });

    test('재개한 RUNNING 타이머는 paused_at과 상관없이 started_at(재개 시각)부터 센다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        elapsedTime: 300,
      ).copyWith(pausedAt: DateTime.utc(2026, 11, 6, 9, 50, 0));

      expect(displayElapsed(timer, now), const Duration(seconds: 330));
    });

    test('PAUSED면 저장값을 그대로 쓴다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.paused,
        startedAt: startedAt,
        elapsedTime: 300,
      );

      expect(displayElapsed(timer, now), const Duration(seconds: 300));
    });

    test('COMPLETED·CANCELLED면 저장값을 그대로 쓴다', () {
      for (final status in [TimerStatus.completed, TimerStatus.cancelled]) {
        final timer = makeTimer(
          id: 't1',
          status: status,
          startedAt: startedAt,
          elapsedTime: 3600,
        );

        expect(displayElapsed(timer, now), const Duration(seconds: 3600));
      }
    });

    test('RUNNING인데 started_at이 없으면 저장값을 그대로 쓴다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        elapsedTime: 60,
      );

      expect(displayElapsed(timer, now), const Duration(seconds: 60));
    });

    test('now가 started_at보다 이르면 실행 구간을 0으로 본다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: startedAt,
        elapsedTime: 100,
      );

      expect(
        displayElapsed(timer, DateTime.utc(2026, 11, 6, 9, 59, 50)),
        const Duration(seconds: 100),
      );
    });

    test('started_at의 타임존 표기와 상관없이 같은 시각으로 계산한다', () {
      final timer = makeTimer(
        id: 't1',
        status: TimerStatus.running,
        startedAt: DateTime.parse('2026-11-06T19:00:00+0900'),
        elapsedTime: 0,
      );

      expect(displayElapsed(timer, now), const Duration(seconds: 30));
    });
  });
}
