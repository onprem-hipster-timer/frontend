import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

/// 2027년 [month]월 [day]일 (2027년 3월 1일은 월요일)
DateTime date(int month, int day) => DateTime.utc(2027, month, day);

/// UTC 시각
DateTime utc(int month, int day, int hour, [int minute = 0]) =>
    DateTime.utc(2027, month, day, hour, minute);

void main() {
  setUpAll(tz.initializeTimeZones);

  group('시간별', () {
    test('날짜가 열, 하루 범위를 슬롯 분으로 나눈 시각이 줄이고 칸은 날짜별로 위에서 아래 순서다', () {
      final grid = MeetingGrid.of(makeMeeting());

      expect(grid.mode, MeetingMode.hourly);
      expect(grid.columns, 5);
      expect(grid.rows, 24);
      expect(grid.cells, hasLength(120));
      expect(grid.columnDays, [for (var d = 1; d <= 5; d++) date(3, d)]);
      expect(grid.rowMinutes.first, 6 * 60);
      expect(grid.rowMinutes.last, 17 * 60 + 30);
      expect(grid.cells[24].column, 1);
      expect(grid.cells[24].row, 0);
    });

    test('칸은 미팅 시간대(서울)의 벽시계 시각을 UTC 구간으로 바꾼 것이다', () {
      final grid = MeetingGrid.of(makeMeeting());

      expect(grid.at(0, 0)!.span, TimeSpan(utc(2, 28, 21), utc(2, 28, 21, 30)));
      expect(grid.at(4, 23)!.span, TimeSpan(utc(3, 5, 8, 30), utc(3, 5, 9)));
    });

    test('같은 날의 이웃한 칸만 이어지고 다음 날 첫 칸은 앞 날 마지막 칸과 이어지지 않는다', () {
      final grid = MeetingGrid.of(makeMeeting());

      expect(grid.at(0, 0)!.joinsPrevious, isFalse);
      expect(grid.at(0, 1)!.joinsPrevious, isTrue);
      expect(grid.at(1, 0)!.joinsPrevious, isFalse);
    });

    test('하루 범위가 슬롯 분으로 나누어떨어지지 않으면 마지막 칸은 범위 끝에서 끝난다', () {
      final grid = MeetingGrid.of(
        makeMeeting(
          startDate: date(3, 1),
          endDate: date(3, 1),
          startTime: '06:00:00',
          endTime: '07:00:00',
          timeSlotMinutes: 25,
        ),
      );

      expect(grid.rowMinutes, [360, 385, 410]);
      expect(grid.at(0, 2)!.endMinute, 420);
      expect(grid.at(0, 2)!.span.length, const Duration(minutes: 10));
    });

    test('끝이 00:00이면 마지막 칸은 다음 날 0시에 끝난다', () {
      final grid = MeetingGrid.of(
        makeMeeting(
          startDate: date(3, 1),
          endDate: date(3, 1),
          startTime: '23:00:00',
          endTime: '00:00:00',
          timeSlotMinutes: 60,
        ),
      );

      expect(grid.cells.single.endMinute, minutesPerDay);
      expect(grid.cells.single.span, TimeSpan(utc(3, 1, 14), utc(3, 1, 15)));
    });

    test('제외 날짜는 열이 없다', () {
      final grid = MeetingGrid.of(
        makeMeeting(
          endDate: date(3, 3),
          excludedDates: [DateTime.parse('2027-03-02')],
        ),
      );

      expect(grid.columnDays, [date(3, 1), date(3, 3)]);
    });

    test('서울이 아닌 시간대는 그 시간대의 벽시계로 칸을 만든다', () {
      final grid = MeetingGrid.of(
        makeMeeting(
          timezone: 'Asia/Kolkata',
          startDate: date(3, 1),
          endDate: date(3, 1),
          startTime: '09:00:00',
          endTime: '10:00:00',
          timeSlotMinutes: 60,
        ),
      );

      expect(
        grid.cells.single.span,
        TimeSpan(utc(3, 1, 3, 30), utc(3, 1, 4, 30)),
      );
    });

    test('일광 절약 시간이 바뀌는 시간대는 같은 벽시계 줄이라도 날마다 UTC가 다르다', () {
      // 뉴욕은 2027년 3월 14일(일)에 일광 절약 시간이 시작한다
      final grid = MeetingGrid.of(
        makeMeeting(
          timezone: 'America/New_York',
          startDate: date(3, 13),
          endDate: date(3, 15),
          startTime: '09:00:00',
          endTime: '10:00:00',
          timeSlotMinutes: 60,
        ),
      );

      expect(
        [for (final cell in grid.cells) cell.span.start],
        [utc(3, 13, 14), utc(3, 14, 13), utc(3, 15, 13)],
      );
    });

    test('일광 절약 시간이 시작하는 날 없는 시각만으로 된 칸은 비우고 앞뒤 칸은 이어진다', () {
      final grid = MeetingGrid.of(
        makeMeeting(
          timezone: 'America/New_York',
          startDate: date(3, 14),
          endDate: date(3, 14),
          startTime: '01:00:00',
          endTime: '04:00:00',
          timeSlotMinutes: 60,
        ),
      );

      expect(grid.rows, 3);
      expect(grid.at(0, 1), isNull);
      expect(grid.at(0, 0)!.span, TimeSpan(utc(3, 14, 6), utc(3, 14, 7)));
      expect(grid.at(0, 2)!.span, TimeSpan(utc(3, 14, 7), utc(3, 14, 8)));
      expect(grid.at(0, 2)!.joinsPrevious, isTrue);
    });

    test('일광 절약 시간이 끝나는 날 겹치는 벽시계 한 시간은 앞의 칸이 두 시간을 덮는다', () {
      // 뉴욕은 2027년 11월 7일(일) 2시에 1시로 돌아간다
      final grid = MeetingGrid.of(
        makeMeeting(
          timezone: 'America/New_York',
          startDate: date(11, 7),
          endDate: date(11, 7),
          startTime: '01:00:00',
          endTime: '03:00:00',
          timeSlotMinutes: 60,
        ),
      );

      expect(grid.at(0, 0)!.span, TimeSpan(utc(11, 7, 5), utc(11, 7, 7)));
      expect(grid.at(0, 1)!.span, TimeSpan(utc(11, 7, 7), utc(11, 7, 8)));
    });
  });

  group('날짜별', () {
    MeetingGrid daily({
      required DateTime from,
      required DateTime to,
      String timezone = 'Asia/Seoul',
      List<DateTime> excluded = const [],
      String endTime = '00:00:00',
    }) => MeetingGrid.of(
      makeMeeting(
        timezone: timezone,
        startDate: from,
        endDate: to,
        excludedDates: excluded,
        mode: MeetingMode.daily,
        startTime: '00:00:00',
        endTime: endTime,
      ),
    );

    test('일요일부터 한 주가 한 줄인 달력이고 하루가 한 칸이다', () {
      final grid = daily(from: date(3, 1), to: date(3, 14));

      expect(grid.mode, MeetingMode.daily);
      expect(grid.columns, 7);
      expect(grid.rows, 3);
      expect(grid.cells, hasLength(14));
      expect(grid.at(0, 0), isNull, reason: '2월 28일은 기간 밖');
      expect(grid.at(1, 0)!.day, date(3, 1));
      expect(grid.at(0, 1)!.day, date(3, 7));
      expect(grid.at(0, 2)!.day, date(3, 14));
    });

    test('하루 칸은 그날 0시부터 다음 날 0시까지의 구간이다', () {
      final grid = daily(from: date(3, 1), to: date(3, 2));

      expect(grid.cells.first.span, TimeSpan(utc(2, 28, 15), utc(3, 1, 15)));
      expect(grid.cells.first.endMinute, minutesPerDay);
    });

    test('이어지는 날끼리 이어지고 제외 날짜가 끼면 끊긴다', () {
      final grid = daily(
        from: date(3, 1),
        to: date(3, 5),
        excluded: [date(3, 3)],
      );

      expect(
        [for (final cell in grid.cells) cell.joinsPrevious],
        [false, true, false, true],
      );
    });

    test('하루 범위가 하루 전체가 아니면 날짜가 이어져도 칸은 이어지지 않는다', () {
      final grid = daily(from: date(3, 1), to: date(3, 2), endTime: '12:00:00');

      expect(grid.cells.last.joinsPrevious, isFalse);
      expect(grid.cells.first.span.length, const Duration(hours: 12));
    });

    test('일광 절약 시간이 바뀌는 날의 칸은 23·25시간이고 앞뒤 날과 이어진다', () {
      final spring = daily(
        from: date(3, 13),
        to: date(3, 15),
        timezone: 'America/New_York',
      );
      final fall = daily(
        from: date(11, 6),
        to: date(11, 8),
        timezone: 'America/New_York',
      );

      expect(
        [for (final cell in spring.cells) cell.span.length.inHours],
        [24, 23, 24],
      );
      expect(
        [for (final cell in fall.cells) cell.span.length.inHours],
        [24, 25, 24],
      );
      expect(spring.cells.skip(1).every((cell) => cell.joinsPrevious), isTrue);
      expect(fall.cells.skip(1).every((cell) => cell.joinsPrevious), isTrue);
    });

    test('기간의 날이 모두 제외되면 칸이 없다', () {
      final grid = daily(
        from: date(3, 1),
        to: date(3, 2),
        excluded: [date(3, 1), date(3, 2)],
      );

      expect(grid.cells, isEmpty);
      expect(grid.rows, 0);
    });
  });

  group('요일별', () {
    MeetingGrid weekly(DateTime from) => MeetingGrid.of(
      makeMeeting(
        startDate: from,
        endDate: from.add(const Duration(days: 6)),
        mode: MeetingMode.weekly,
        startTime: '00:00:00',
        endTime: '00:00:00',
      ),
    );

    test('기간이 어느 요일에 시작해도 월요일부터 일곱 칸이 한 줄이다', () {
      final grid = weekly(date(3, 3));

      expect(grid.mode, MeetingMode.weekly);
      expect(grid.rows, 1);
      expect(
        [for (final cell in grid.cells) cell.column],
        [0, 1, 2, 3, 4, 5, 6],
      );
      expect(grid.cells.first.day, date(3, 8), reason: '월요일');
      expect(grid.cells[2].day, date(3, 3), reason: '수요일');
    });

    test('이웃한 요일끼리 이어지고 일요일과 월요일은 잇지 않는다', () {
      final grid = weekly(date(3, 3));

      expect(grid.cells.first.joinsPrevious, isFalse);
      expect(grid.cells.skip(1).every((cell) => cell.joinsPrevious), isTrue);
    });

    test('이어진 요일의 구간은 첫 요일의 날부터 그 수만큼의 날이다', () {
      final grid = weekly(date(3, 3));
      final tuesdayToWednesday = [grid.at(1, 0)!, grid.at(2, 0)!];

      expect(tuesdayToWednesday.first.day, date(3, 9));
      expect(
        grid.spanOf(tuesdayToWednesday),
        TimeSpan(utc(3, 8, 15), utc(3, 10, 15)),
      );
    });
  });

  group('자리', () {
    test('격자 밖 자리는 칸이 없다', () {
      final grid = MeetingGrid.of(makeMeeting());

      expect(grid.at(-1, 0), isNull);
      expect(grid.at(5, 0), isNull);
      expect(grid.at(0, 24), isNull);
    });

    test('두 꼭짓점을 어느 쪽에서 잡아도 같은 사각형 안의 칸을 화면 순서로 준다', () {
      final grid = MeetingGrid.of(makeMeeting());
      final forward = grid.within((0, 2), (1, 3));
      final backward = grid.within((1, 3), (0, 2));

      expect(forward, backward);
      expect(
        [for (final cell in forward) (cell.column, cell.row)],
        [(0, 2), (0, 3), (1, 2), (1, 3)],
      );
    });

    test('시간별·날짜별 구간은 첫 칸 시작부터 마지막 칸 끝까지다', () {
      final grid = MeetingGrid.of(makeMeeting());

      expect(
        grid.spanOf([grid.at(0, 0)!, grid.at(0, 1)!]),
        TimeSpan(utc(2, 28, 21), utc(2, 28, 22)),
      );
    });
  });

  group('농도 단계', () {
    test('아무도 안 되거나 다른 참여자가 없으면 0이다', () {
      expect(availabilityShade(0, 5), 0);
      expect(availabilityShade(3, 0), 0);
    });

    test('모두 되면 5다', () {
      expect(availabilityShade(5, 5), 5);
      expect(availabilityShade(1, 1), 5);
    });

    test('다른 참여자가 다섯이면 한 명마다 한 단계씩 진해진다', () {
      expect(
        [for (var n = 0; n <= 5; n++) availabilityShade(n, 5)],
        [0, 1, 2, 3, 4, 5],
      );
    });

    test('많으면 비율을 네 단계로 올려 나누고 모두가 아니면 4를 넘지 않는다', () {
      expect(
        [for (var n = 1; n <= 10; n++) availabilityShade(n, 10)],
        [1, 1, 2, 2, 2, 3, 3, 4, 4, 5],
      );
      expect(availabilityShade(99, 100), 4);
    });
  });
}
