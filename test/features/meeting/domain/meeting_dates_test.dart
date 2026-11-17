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

  group('기간으로 고르기', () {
    test('시작일부터 끝나는 날까지 모두 든다', () {
      final dates = MeetingDates.range(march(3), march(7));
      expect(daysOf(dates), [3, 4, 5, 6, 7]);
      expect(dates.span, 5);
      expect(dates.excluded, isEmpty);
    });

    test('끝나는 날을 시작일보다 앞에 눌러도 앞의 날부터다', () {
      expect(daysOf(MeetingDates.range(march(7), march(3))), [3, 4, 5, 6, 7]);
    });

    test('같은 날을 두 번 누르면 하루다', () {
      final dates = MeetingDates.range(march(3), march(3));
      expect(daysOf(dates), [3]);
      expect(dates.span, 1);
    });

    test('시각이 붙은 값도 그날로 본다', () {
      final dates = MeetingDates.range(
        DateTime(2027, 3, 2, 15),
        DateTime(2027, 3, 4, 1),
      );
      expect(daysOf(dates), [2, 3, 4]);
      expect(dates.contains(DateTime(2027, 3, 3, 23)), isTrue);
    });

    test('제외 날짜는 첫날과 마지막 날 사이의 것만 남긴다', () {
      final dates = MeetingDates.range(
        march(3),
        march(7),
        excluded: [march(1), march(3), march(5), march(7), march(9)],
      );
      expect(daysOf(dates), [3, 4, 6, 7]);
      expect(dates.excluded, [march(5)]);
    });
  });

  group('기간 안의 날 빼기', () {
    final week = MeetingDates.range(march(1), march(7));

    test('가운데 날을 빼고, 다시 누르면 되돌린다', () {
      final out = week.toggleExcluded(march(3));
      expect(out.excluded, [march(3)]);
      expect(out.toggleExcluded(march(3)).excluded, isEmpty);
    });

    test('첫날과 마지막 날은 뺄 수 없다', () {
      expect(week.canExclude(march(1)), isFalse);
      expect(week.canExclude(march(7)), isFalse);
      expect(week.toggleExcluded(march(1)).days, week.days);
      expect(week.toggleExcluded(march(7)).days, week.days);
      expect(week.canExclude(march(4)), isTrue);
    });

    test('기간 밖의 날은 뺄 수 없다', () {
      expect(week.canExclude(march(9)), isFalse);
      expect(week.toggleExcluded(march(9)).days, week.days);
    });

    test('주말 빼기는 첫날·마지막 날이 아닌 토·일요일만 뺀다', () {
      // 3월 1일(월)~14일(일): 6·7·13일이 가운데 주말, 14일(일)은 마지막 날이다
      final twoWeeks = MeetingDates.range(march(1), march(14));
      expect(twoWeeks.weekendsInside, [march(6), march(7), march(13)]);
      expect(twoWeeks.withoutWeekends().excluded, [
        march(6),
        march(7),
        march(13),
      ]);
    });

    test('가운데 주말이 없으면 주말 빼기는 할 것이 없다', () {
      expect(MeetingDates.range(march(1), march(5)).weekendsInside, isEmpty);
      // 토요일에 시작해 일요일에 끝나면 주말이 모두 첫날·마지막 날이다
      expect(MeetingDates.range(march(6), march(7)).weekendsInside, isEmpty);
    });

    test('뺀 날을 모두 되돌린다', () {
      final dates = week.toggleExcluded(march(3)).toggleExcluded(march(4));
      expect(dates.withoutExclusions().days, week.days);
    });

    test('이어진 7일이고 뺀 날이 없을 때만 한 주다', () {
      expect(week.isWeek, isTrue);
      expect(week.toggleExcluded(march(3)).isWeek, isFalse);
      expect(MeetingDates.range(march(1), march(6)).isWeek, isFalse);
      expect(MeetingDates.none.isWeek, isFalse);
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
    test('첫날에서 3개월 뒤 같은 날(없으면 말일)까지가 상한 안이다', () {
      expect(
        MeetingDates.range(
          march(31),
          DateTime.utc(2027, 6, 30),
        ).withinMaxPeriod,
        isTrue,
      );
      expect(
        MeetingDates.range(march(31), DateTime.utc(2027, 7, 1)).withinMaxPeriod,
        isFalse,
      );
    });

    test('끝나는 날을 앞에 눌러도 앞의 날에서 센다', () {
      expect(
        MeetingDates.range(
          march(31),
          DateTime.utc(2026, 12, 31),
        ).withinMaxPeriod,
        isTrue,
      );
      expect(
        MeetingDates.range(
          march(31),
          DateTime.utc(2026, 12, 30),
        ).withinMaxPeriod,
        isFalse,
      );
    });

    test('고른 날이 없으면 상한 안이다', () {
      expect(MeetingDates.none.withinMaxPeriod, isTrue);
    });
  });
}
