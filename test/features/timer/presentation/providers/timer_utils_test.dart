import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/timer/presentation/providers/timer_providers.dart';

// 참고: formatDuration·formatTime은 lib/core/utils/time_formatters.dart로 이동했으며
// 해당 테스트는 test/core/utils/time_formatters_test.dart에 있습니다.
void main() {
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
