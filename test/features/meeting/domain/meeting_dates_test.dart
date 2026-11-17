import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

List<int> daysOf(MeetingDates dates) => [for (final d in dates.days) d.day];

void main() {
  group('날짜만 담는 값', () {
    test('시각을 버리고 그날의 UTC 자정으로 맞춘다', () {
      expect(calendarDay(DateTime(2027, 3, 1, 23, 59)), march(1));
      expect(calendarDay(DateTime.utc(2027, 3, 1, 9)), march(1));
    });

    test('요일 번호는 월요일이 0, 일요일이 6이다', () {
      expect(weekdayNumber(march(1)), 0);
      expect(weekdayNumber(march(7)), 6);
    });
  });

  group('달 더하기', () {
    test('같은 날로 간다', () {
      expect(addMonthsClamped(march(1), 3), DateTime.utc(2027, 6, 1));
    });

    test('그 달에 같은 날이 없으면 말일로 간다', () {
      expect(addMonthsClamped(march(31), 3), DateTime.utc(2027, 6, 30));
      expect(
        addMonthsClamped(DateTime.utc(2027, 11, 30), 3),
        DateTime.utc(2028, 2, 29),
      );
    });
  });

  group('고르고 빼기', () {
    test('누른 날만 들고 난다', () {
      var dates = MeetingDates.none.toggle(march(1)).toggle(march(5));
      expect(daysOf(dates), [1, 5]);
      expect(dates.span, 5);

      dates = dates.toggle(march(3)).toggle(march(5));
      expect(daysOf(dates), [1, 3]);
    });

    test('순서를 바꿔 눌러도 같은 날짜가 된다', () {
      final forward = MeetingDates.none
          .toggle(march(2))
          .toggle(march(4))
          .toggle(march(6));
      final backward = MeetingDates.none
          .toggle(march(6))
          .toggle(march(4))
          .toggle(march(2));
      expect(daysOf(forward), daysOf(backward));
    });

    test('같은 날을 두 번 누르면 처음으로 돌아간다', () {
      final dates = MeetingDates.none.toggle(march(3)).toggle(march(3));
      expect(dates.isEmpty, isTrue);
      expect(dates.span, 0);
    });

    test('2주 떨어진 두 날을 고르면 그 두 날만 고르고 사이의 같은 요일 날은 들지 않는다', () {
      final dates = MeetingDates.none.toggle(march(1)).toggle(march(15));
      expect(daysOf(dates), [1, 15]);
      expect(dates.span, 15);
    });

    test('기간 가운데의 날을 빼면 그날만 빠진다', () {
      final twoWeeks = MeetingDates.of([
        for (var day = 1; day <= 14; day++) march(day),
      ]);
      final dates = twoWeeks.toggle(march(4));
      expect(daysOf(dates), [1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]);
    });

    test('같은 날을 여러 번 넣어도 한 번만 든다', () {
      final dates = MeetingDates.of([march(3), march(1), march(3)]);
      expect(daysOf(dates), [1, 3]);
    });

    test('끝날을 빼면 그날만 빠지고 기간이 줄어든다', () {
      final twoWeeks = MeetingDates.of([
        for (var day = 1; day <= 14; day++) march(day),
      ]);
      final dates = twoWeeks.toggle(march(14));
      expect(daysOf(dates), [for (var day = 1; day <= 13; day++) day]);
      expect(dates.span, 13);
    });

    test('첫날을 빼면 다음 고른 날이 첫날이 된다', () {
      final dates = MeetingDates.of([
        march(1),
        march(3),
        march(8),
      ]).toggle(march(1));
      expect(daysOf(dates), [3, 8]);
      expect(dates.span, 6);
    });

    test('시각이 붙은 값으로 눌러도 같은 날로 본다', () {
      final dates = MeetingDates.none.toggle(DateTime(2027, 3, 2, 15));
      expect(dates.contains(DateTime(2027, 3, 2, 1)), isTrue);
      expect(dates.toggle(DateTime(2027, 3, 2, 8)).isEmpty, isTrue);
    });
  });

  group('기간', () {
    test('이어지는 날을 시작일부터 센다', () {
      final week = MeetingDates.period(DateTime(2027, 3, 3, 10), 7);
      expect(daysOf(week), [3, 4, 5, 6, 7, 8, 9]);
    });

    test('달을 넘어가도 이어진다', () {
      final week = MeetingDates.period(DateTime.utc(2027, 2, 26), 7);
      expect(week.last, march(4));
    });
  });

  group('제외 날짜', () {
    test('첫날과 마지막 날 사이에서 고르지 않은 날이다', () {
      final dates = MeetingDates.of([march(1), march(4), march(6)]);
      expect(dates.excluded, [march(2), march(3), march(5)]);
    });

    test('이어진 날이나 하루면 없다', () {
      expect(MeetingDates.period(march(1), 5).excluded, isEmpty);
      expect(MeetingDates.of([march(1)]).excluded, isEmpty);
      expect(MeetingDates.none.excluded, isEmpty);
    });

    test('기간과 제외 날짜로 고른 날을 그대로 다시 만든다', () {
      final dates = MeetingDates.of([march(1), march(15), march(20)]);
      final excluded = dates.excluded.toSet();
      final rebuilt = [
        for (var i = 0; i < dates.span; i++)
          if (!excluded.contains(dates.first.add(Duration(days: i))))
            dates.first.add(Duration(days: i)),
      ];
      expect(rebuilt, dates.days);
    });
  });

  group('기간 상한', () {
    final start = MeetingDates.none.toggle(march(31));

    test('첫날에서 3개월 뒤 같은 날(없으면 말일)까지 더할 수 있다', () {
      expect(start.canAdd(DateTime.utc(2027, 6, 30)), isTrue);
      expect(start.canAdd(DateTime.utc(2027, 7, 1)), isFalse);
    });

    test('앞쪽으로 더할 때는 새 첫날에서 센다', () {
      expect(start.canAdd(DateTime.utc(2026, 12, 31)), isTrue);
      expect(start.canAdd(DateTime.utc(2026, 12, 30)), isFalse);
    });

    test('고른 날이 없으면 어느 날이든 더할 수 있다', () {
      expect(MeetingDates.none.canAdd(DateTime.utc(2030, 1, 1)), isTrue);
    });
  });
}
