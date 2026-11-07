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
}
