import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/calendar/presentation/state/calendar_state.dart';
import 'package:momeet/features/calendar/presentation/utils/calendar_date_utils.dart';

void main() {
  group('autoMonthEventsPerDay', () {
    // 기기별 칸 높이(앱바·도구 줄·내비를 뺀 달력 높이 ÷ 6)에서 잰 값
    test('칸에 읽히는 줄(18 × 배율)이 들어가는 만큼 보인다', () {
      expect(autoMonthEventsPerDay(cellHeight: 96.3, textScale: 1), 3);
      expect(autoMonthEventsPerDay(cellHeight: 143, textScale: 1), 5);
      expect(autoMonthEventsPerDay(cellHeight: 91, textScale: 1), 2);
    });

    test('글자가 커지면 줄이 커져 덜 보인다', () {
      expect(autoMonthEventsPerDay(cellHeight: 96.3, textScale: 1.3), 2);
      expect(autoMonthEventsPerDay(cellHeight: 143, textScale: 1.3), 4);
    });

    test('한 줄도 들어가지 않는 칸은 0, 아주 높아도 여섯을 넘지 않는다', () {
      expect(autoMonthEventsPerDay(cellHeight: 30, textScale: 1.3), 0);
      expect(autoMonthEventsPerDay(cellHeight: 60, textScale: 1), 1);
      expect(autoMonthEventsPerDay(cellHeight: 500, textScale: 1), 6);
    });
  });

  group('기간', () {
    test('보기마다 그 날이 든 기간의 첫날을 돌려준다', () {
      final day = DateTime(2026, 11, 12, 15);
      expect(
        periodStart(CalendarViewType.month, day, DateTime.sunday),
        DateTime(2026, 11, 1),
      );
      expect(
        periodStart(CalendarViewType.week, day, DateTime.sunday),
        DateTime(2026, 11, 8),
      );
      expect(
        periodStart(CalendarViewType.week, day, DateTime.monday),
        DateTime(2026, 11, 9),
      );
      expect(
        periodStart(CalendarViewType.day, day, DateTime.sunday),
        DateTime(2026, 11, 12),
      );
    });

    test('기간을 앞뒤로 옮기고 달·해 경계를 넘는다', () {
      expect(
        shiftPeriod(CalendarViewType.month, DateTime(2026, 12, 1), 1),
        DateTime(2027, 1, 1),
      );
      expect(
        shiftPeriod(CalendarViewType.week, DateTime(2026, 11, 29), 1),
        DateTime(2026, 12, 6),
      );
      expect(
        shiftPeriod(CalendarViewType.day, DateTime(2026, 3, 1), -1),
        DateTime(2026, 2, 28),
      );
    });

    test('기간 안의 날인지 본다', () {
      expect(
        periodContains(
          CalendarViewType.month,
          DateTime(2026, 11, 1),
          DateTime(2026, 11, 30),
          7,
        ),
        isTrue,
      );
      expect(
        periodContains(
          CalendarViewType.month,
          DateTime(2026, 11, 1),
          DateTime(2026, 12, 1),
          7,
        ),
        isFalse,
      );
    });
  });
}
