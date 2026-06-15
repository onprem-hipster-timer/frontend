import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/calendar/presentation/utils/schedule_formatters.dart';

void main() {
  group('isIncludeDay', () {
    test('당일 일정은 해당 날짜를 포함한다', () {
      final start = DateTime(2026, 6, 3, 9);
      final end = DateTime(2026, 6, 3, 18);
      expect(isIncludeDay(start, end, DateTime(2026, 6, 3)), isTrue);
    });

    test('멀티-데이 일정의 시작일을 포함한다', () {
      final start = DateTime(2026, 6, 3, 9);
      final end = DateTime(2026, 6, 5, 18);
      expect(isIncludeDay(start, end, DateTime(2026, 6, 3)), isTrue);
    });

    test('멀티-데이 일정의 종료일을 포함한다', () {
      final start = DateTime(2026, 6, 3, 9);
      final end = DateTime(2026, 6, 5, 18);
      expect(isIncludeDay(start, end, DateTime(2026, 6, 5)), isTrue);
    });

    test('멀티-데이 일정의 중간 날짜를 포함한다', () {
      final start = DateTime(2026, 6, 3, 9);
      final end = DateTime(2026, 6, 5, 18);
      expect(isIncludeDay(start, end, DateTime(2026, 6, 4)), isTrue);
    });

    test('기간 이전 날짜는 포함하지 않는다', () {
      final start = DateTime(2026, 6, 3, 9);
      final end = DateTime(2026, 6, 5, 18);
      expect(isIncludeDay(start, end, DateTime(2026, 6, 2)), isFalse);
    });

    test('기간 이후 날짜는 포함하지 않는다', () {
      final start = DateTime(2026, 6, 3, 9);
      final end = DateTime(2026, 6, 5, 18);
      expect(isIncludeDay(start, end, DateTime(2026, 6, 6)), isFalse);
    });

    test('1일 종일 일정은 시작일만 포함한다 (자정 종료는 exclusive)', () {
      final start = DateTime(2026, 4, 7);
      final end = DateTime(2026, 4, 8);
      expect(isIncludeDay(start, end, DateTime(2026, 4, 7)), isTrue);
      expect(isIncludeDay(start, end, DateTime(2026, 4, 8)), isFalse);
    });

    test('멀티-데이 종일 일정은 종료 자정 당일을 포함하지 않는다', () {
      final start = DateTime(2026, 4, 7);
      final end = DateTime(2026, 4, 9);
      expect(isIncludeDay(start, end, DateTime(2026, 4, 7)), isTrue);
      expect(isIncludeDay(start, end, DateTime(2026, 4, 8)), isTrue);
      expect(isIncludeDay(start, end, DateTime(2026, 4, 9)), isFalse);
    });
  });
}
