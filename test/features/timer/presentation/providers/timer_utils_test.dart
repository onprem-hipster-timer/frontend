import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';

void main() {
  // ============================================================
  // formatDuration
  // ============================================================
  group('formatDuration', () {
    test('0초는 00:00:00', () {
      expect(formatDuration(Duration.zero), '00:00:00');
    });

    test('59초는 00:00:59', () {
      expect(formatDuration(const Duration(seconds: 59)), '00:00:59');
    });

    test('60초(1분)는 00:01:00', () {
      expect(formatDuration(const Duration(seconds: 60)), '00:01:00');
    });

    test('3661초(1시간 1분 1초)는 01:01:01', () {
      expect(formatDuration(const Duration(seconds: 3661)), '01:01:01');
    });

    test('3600초(1시간)는 01:00:00', () {
      expect(formatDuration(const Duration(hours: 1)), '01:00:00');
    });

    test('36000초(10시간)는 10:00:00', () {
      expect(formatDuration(const Duration(hours: 10)), '10:00:00');
    });

    test('90061초(25시간 1분 1초)는 25:01:01', () {
      expect(formatDuration(const Duration(seconds: 90061)), '25:01:01');
    });
  });

  // ============================================================
  // formatTime
  // ============================================================
  group('formatTime', () {
    test('자정(UTC)을 로컬 HH:MM으로 변환한다', () {
      final dt = DateTime.utc(2026, 6, 15, 0, 0);
      final result = formatTime(dt);
      expect(result, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    test('오후 시간도 정상 표시한다', () {
      final dt = DateTime(2026, 6, 15, 23, 59);
      expect(formatTime(dt), '23:59');
    });

    test('새벽 시간을 앞자리 0으로 패딩한다', () {
      final dt = DateTime(2026, 6, 15, 1, 5);
      expect(formatTime(dt), '01:05');
    });
  });

  // ============================================================
  // formatDate
  // ============================================================
  group('formatDate', () {
    test('MM/DD 형식으로 변환한다', () {
      final dt = DateTime(2026, 2, 22);
      expect(formatDate(dt), '02/22');
    });

    test('한 자리 월/일을 0으로 패딩한다', () {
      final dt = DateTime(2026, 1, 5);
      expect(formatDate(dt), '01/05');
    });

    test('12월 31일 표시', () {
      final dt = DateTime(2026, 12, 31);
      expect(formatDate(dt), '12/31');
    });
  });

  // ============================================================
  // isSameDay
  // ============================================================
  group('isSameDay', () {
    test('같은 날이면 true', () {
      final a = DateTime(2026, 2, 22, 10, 30);
      final b = DateTime(2026, 2, 22, 23, 59);
      expect(isSameDay(a, b), isTrue);
    });

    test('다른 날이면 false', () {
      final a = DateTime(2026, 2, 22);
      final b = DateTime(2026, 2, 23);
      expect(isSameDay(a, b), isFalse);
    });

    test('같은 날 자정과 직전은 다른 날이다', () {
      final a = DateTime(2026, 2, 22, 0, 0, 0);
      final b = DateTime(2026, 2, 21, 23, 59, 59);
      expect(isSameDay(a, b), isFalse);
    });

    test('UTC와 로컬이 같은 날 기준으로 비교된다', () {
      final a = DateTime(2026, 2, 22, 5, 0);
      final b = DateTime.utc(2026, 2, 22, 20, 0).toLocal();
      // 동일 로컬 날짜인지 확인
      expect(isSameDay(a, b), a.day == b.day);
    });
  });
}
