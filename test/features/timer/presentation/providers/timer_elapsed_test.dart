import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';
import 'package:momeet/shared/api/rest/models/timer_status.dart';

void main() {
  group('calculateElapsed', () {
    // ============================================================
    // null / 비활성 상태
    // ============================================================
    group('비활성 상태', () {
      test('status가 null이면 Duration.zero를 반환한다', () {
        final result = calculateElapsed(status: null, elapsedTime: 120);
        expect(result, Duration.zero);
      });

      test('PAUSED 상태면 elapsedTime을 그대로 반환한다', () {
        final result = calculateElapsed(
          status: TimerStatus.paused,
          elapsedTime: 300,
        );
        expect(result, const Duration(seconds: 300));
      });

      test('COMPLETED 상태면 elapsedTime을 그대로 반환한다', () {
        final result = calculateElapsed(
          status: TimerStatus.completed,
          elapsedTime: 3600,
        );
        expect(result, const Duration(seconds: 3600));
      });

      test('CANCELLED 상태면 elapsedTime을 그대로 반환한다', () {
        final result = calculateElapsed(
          status: TimerStatus.cancelled,
          elapsedTime: 100,
        );
        expect(result, const Duration(seconds: 100));
      });

      test('PAUSED 상태에서 elapsedTime=0이면 Duration.zero를 반환한다', () {
        final result = calculateElapsed(
          status: TimerStatus.paused,
          elapsedTime: 0,
        );
        expect(result, Duration.zero);
      });
    });

    // ============================================================
    // RUNNING 상태
    // ============================================================
    group('RUNNING 상태', () {
      test('startedAt 기준으로 현재 구간을 더한다', () {
        final startedAt = DateTime.utc(2026, 2, 22, 10, 0, 0);
        final now = DateTime.utc(2026, 2, 22, 10, 0, 30);

        final result = calculateElapsed(
          status: TimerStatus.running,
          elapsedTime: 100,
          startedAt: startedAt,
          now: now,
        );

        // 100 (누적) + 30 (현재 구간) = 130
        expect(result, const Duration(seconds: 130));
      });

      test('pausedAt이 있으면 pausedAt 기준으로 현재 구간을 더한다', () {
        final startedAt = DateTime.utc(2026, 2, 22, 10, 0, 0);
        final pausedAt = DateTime.utc(2026, 2, 22, 10, 5, 0);
        final now = DateTime.utc(2026, 2, 22, 10, 5, 20);

        final result = calculateElapsed(
          status: TimerStatus.running,
          elapsedTime: 300,
          startedAt: startedAt,
          pausedAt: pausedAt,
          now: now,
        );

        // 300 (누적) + 20 (pausedAt ~ now) = 320
        expect(result, const Duration(seconds: 320));
      });

      test('startedAt과 pausedAt 모두 null이면 elapsedTime만 반환한다', () {
        final result = calculateElapsed(
          status: TimerStatus.running,
          elapsedTime: 60,
          now: DateTime.utc(2026, 2, 22, 10, 0, 0),
        );

        expect(result, const Duration(seconds: 60));
      });

      test('elapsedTime=0이고 방금 시작했으면 현재 구간만 반환한다', () {
        final startedAt = DateTime.utc(2026, 2, 22, 10, 0, 0);
        final now = DateTime.utc(2026, 2, 22, 10, 0, 5);

        final result = calculateElapsed(
          status: TimerStatus.running,
          elapsedTime: 0,
          startedAt: startedAt,
          now: now,
        );

        expect(result, const Duration(seconds: 5));
      });

      test('now이 startedAt보다 이전이면 0으로 clamp된다', () {
        final startedAt = DateTime.utc(2026, 2, 22, 10, 0, 0);
        final now = DateTime.utc(2026, 2, 22, 9, 59, 50);

        final result = calculateElapsed(
          status: TimerStatus.running,
          elapsedTime: 0,
          startedAt: startedAt,
          now: now,
        );

        // -10초이지만 0으로 clamp
        expect(result, Duration.zero);
      });

      test('now 파라미터 생략 시 실제 현재 시간을 사용한다', () {
        final startedAt = DateTime.now().toUtc().subtract(
          const Duration(seconds: 10),
        );

        final result = calculateElapsed(
          status: TimerStatus.running,
          elapsedTime: 0,
          startedAt: startedAt,
        );

        // 약 10초 ± 1초 오차 허용
        expect(result.inSeconds, greaterThanOrEqualTo(9));
        expect(result.inSeconds, lessThanOrEqualTo(12));
      });
    });

    // ============================================================
    // 일시정지 → 재개 시나리오
    // ============================================================
    group('일시정지 → 재개 시나리오', () {
      test('일시정지 시 elapsedTime 유지, 0이 되지 않는다', () {
        final pauseResult = calculateElapsed(
          status: TimerStatus.paused,
          elapsedTime: 120,
          startedAt: DateTime.utc(2026, 2, 22, 10, 0, 0),
          pausedAt: DateTime.utc(2026, 2, 22, 10, 2, 0),
        );
        expect(pauseResult, const Duration(seconds: 120));
        expect(pauseResult, isNot(Duration.zero));
      });

      test('재개 후 RUNNING이면 누적 + 현재 구간이다', () {
        final resumeResult = calculateElapsed(
          status: TimerStatus.running,
          elapsedTime: 120,
          startedAt: DateTime.utc(2026, 2, 22, 10, 0, 0),
          pausedAt: DateTime.utc(2026, 2, 22, 10, 3, 0),
          now: DateTime.utc(2026, 2, 22, 10, 3, 15),
        );
        // 120 (누적) + 15 (재개 후 구간) = 135
        expect(resumeResult, const Duration(seconds: 135));
      });
    });
  });
}
