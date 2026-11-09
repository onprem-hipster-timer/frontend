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

  group('isAllDay', () {
    final day = DateTime(2026, 11, 10);

    test('00:00에 시작해 그날 23:59(초 포함)에 끝나면 종일이다', () {
      expect(isAllDay(day, DateTime(2026, 11, 10, 23, 59)), isTrue);
      expect(isAllDay(day, DateTime(2026, 11, 10, 23, 59, 59)), isTrue);
    });

    test('다음 날 00:00에 끝나도 종일이고, 여러 날도 종일이다', () {
      expect(isAllDay(day, DateTime(2026, 11, 11)), isTrue);
      expect(isAllDay(day, DateTime(2026, 11, 12, 23, 59)), isTrue);
    });

    test('00:00이 아닌 시작, 23:59가 아닌 끝, 하루보다 짧으면 종일이 아니다', () {
      expect(
        isAllDay(DateTime(2026, 11, 10, 9), DateTime(2026, 11, 10, 23, 59)),
        isFalse,
      );
      expect(isAllDay(day, DateTime(2026, 11, 10, 18)), isFalse);
      expect(isAllDay(day, day), isFalse);
      expect(isAllDay(day, DateTime(2026, 11, 9, 23, 59)), isFalse);
    });
  });
}
