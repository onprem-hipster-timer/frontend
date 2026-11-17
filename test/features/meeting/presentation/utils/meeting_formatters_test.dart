import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../../meeting_fixtures.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

void main() {
  group('하루 시간 범위', () {
    test('정각 시각을 시:00으로 보인다', () {
      expect(meetingHoursText(makeMeeting()), '6:00 ~ 18:00');
    });

    test('끝이 00:00이면 하루의 끝인 24:00으로 보인다', () {
      final meeting = makeMeeting(startTime: '22:00:00', endTime: '00:00:00');
      expect(meetingHoursText(meeting), '22:00 ~ 24:00');
    });
  });

  group('시간 기준', () {
    test('서울은 한국 시간 기준이다', () {
      expect(timezoneBasisText('Asia/Seoul'), '한국 시간 기준');
    });

    test('그 밖의 시간대는 도시와 지금의 UTC 차이로 보인다', () {
      tz.initializeTimeZones();
      expect(timezoneBasisText('Asia/Kolkata'), 'Kolkata (UTC+05:30) 기준');
    });

    test('모르는 시간대는 이름을 그대로 쓴다', () {
      expect(timezoneBasisText('Mars/Olympus'), 'Mars/Olympus 기준');
    });
  });

  group('제목 자리 글자', () {
    test('이름이 있으면 OO님의 모임 일정이다', () {
      expect(meetingTitlePlaceholder('지현'), '지현님의 모임 일정');
      expect(meetingTitlePlaceholder('  지현 '), '지현님의 모임 일정');
    });

    test('이름이 없거나 비었으면 모임 일정이다', () {
      expect(meetingTitlePlaceholder(null), '모임 일정');
      expect(meetingTitlePlaceholder('   '), '모임 일정');
    });
  });

  test('달 이름은 영문이다', () {
    expect(meetingMonthName(march(1)), 'March');
    expect(meetingMonthName(DateTime.utc(2027, 12)), 'December');
  });

  test('벽시계 분은 시:분이고 다음 날 0시는 24:00이다', () {
    expect(minuteLabel(0), '0:00');
    expect(minuteLabel(9 * 60 + 30), '9:30');
    expect(minuteLabel(9 * 60 + 5), '9:05');
    expect(minuteLabel(minutesPerDay), '24:00');
  });

  group('격자 칸과 선택된 일정 카드', () {
    setUpAll(tz.initializeTimeZones);

    MeetingGrid grid(
      MeetingMode mode, {
      DateTime? from,
      DateTime? to,
      String start = '00:00:00',
      String end = '00:00:00',
    }) => MeetingGrid.of(
      makeMeeting(
        startDate: from ?? march(1),
        endDate: to ?? march(7),
        mode: mode,
        startTime: start,
        endTime: end,
      ),
    );

    MeetingRun runOf(MeetingGrid grid, List<(int, int)> places) => MeetingRun(
      [for (final (column, row) in places) grid.at(column, row)!],
      const {'a', 'b'},
    );

    test('시간별 칸은 날짜와 시각 범위, 카드는 날짜와 첫 칸 시작부터 마지막 칸 끝까지다', () {
      final hourly = grid(
        MeetingMode.hourly,
        to: march(1),
        start: '22:00:00',
        end: '00:00:00',
      );

      expect(
        meetingCellLabel(hourly, hourly.at(0, 3)!),
        '3월 1일 (월) 23:30 ~ 24:00',
      );
      expect(meetingRunText(hourly, runOf(hourly, [(0, 1), (0, 2), (0, 3)])), (
        title: '3월 1일 (월)',
        detail: '22:30 ~ 24:00',
      ));
    });

    test('날짜별 칸은 날짜이고 하루 카드는 하루 종일, 이어진 날은 첫날 ~ 마지막 날과 날 수다', () {
      final daily = grid(
        MeetingMode.daily,
        from: march(29),
        to: DateTime.utc(2027, 4, 5),
      );

      expect(meetingCellLabel(daily, daily.at(1, 0)!), '3월 29일 (월)');
      expect(meetingRunText(daily, runOf(daily, [(1, 0)])), (
        title: '3월 29일 (월)',
        detail: '하루 종일',
      ));
      expect(meetingRunText(daily, runOf(daily, [(1, 0), (2, 0)])), (
        title: '3월 29일 ~ 30일',
        detail: '2일',
      ));
      expect(meetingRunText(daily, runOf(daily, [(3, 0), (4, 0), (5, 0)])), (
        title: '3월 31일 ~ 4월 2일',
        detail: '3일',
      ));
    });

    test('하루 범위가 하루 전체가 아닌 날짜별 하루 카드는 시각 범위를 보인다', () {
      final daily = grid(MeetingMode.daily, to: march(8), end: '12:00:00');

      expect(
        meetingRunText(daily, runOf(daily, [(1, 0)])).detail,
        '0:00 ~ 12:00',
      );
    });

    test('요일별 칸은 요일이고 카드는 요일(이어지면 첫 요일 ~ 마지막 요일)이다', () {
      final weekly = grid(MeetingMode.weekly, from: march(3), to: march(9));

      expect(meetingCellLabel(weekly, weekly.at(6, 0)!), '일요일');
      expect(meetingRunText(weekly, runOf(weekly, [(0, 0)])), (
        title: '월요일',
        detail: '하루 종일',
      ));
      expect(meetingRunText(weekly, runOf(weekly, [(1, 0), (2, 0), (3, 0)])), (
        title: '화요일 ~ 목요일',
        detail: '3일',
      ));
    });
  });
}
