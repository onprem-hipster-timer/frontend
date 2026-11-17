import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_headcount.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

/// 서울 2027년 3월 [day]일 [hour]시 [minute]분의 UTC 시각
DateTime seoul(int day, int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, day, hour - 9, minute);

/// [meeting]의 결과. [cells]는 (시작, 끝, 사람 수)
MeetingResultRead resultOf(
  MeetingRead meeting,
  List<(DateTime, DateTime, int)> cells, {
  int participants = 3,
}) => MeetingResultRead(
  meeting: meeting,
  participantCount: participants,
  availabilityGrid: [
    for (final (start, end, count) in cells)
      AvailabilityCell(
        startTime: start,
        endTime: end,
        count: count,
        unavailableCount: 0,
      ),
  ],
);

void main() {
  setUpAll(tz.initializeTimeZones);

  test('시간별은 칸마다 같은 구간의 결과 칸 사람 수이고, 결과에 없는 칸은 0이다', () {
    final meeting = makeMeeting();
    final headcount = MeetingHeadcount(
      resultOf(meeting, [
        (seoul(1, 6), seoul(1, 6, 30), 2),
        (seoul(1, 6, 30), seoul(1, 7), 3),
        (seoul(2, 17, 30), seoul(2, 18), 1),
      ]),
    );
    final grid = headcount.grid;

    expect(headcount.othersCountAt(grid.at(0, 0)!), 2);
    expect(headcount.othersCountAt(grid.at(0, 1)!), 3);
    expect(headcount.othersCountAt(grid.at(1, 23)!), 1);
    expect(headcount.othersCountAt(grid.at(0, 2)!), 0);
  });

  test('응답의 시각이 다른 시간대 오프셋이어도 같은 순간이면 맞춘다', () {
    final meeting = makeMeeting();
    final result = MeetingResultRead.fromJson({
      'meeting': meeting.toJson(),
      'participant_count': 2,
      'availability_grid': [
        {
          'start_time': '2027-03-01T06:00:00+0900',
          'end_time': '2027-03-01T06:30:00+0900',
          'count': 2,
          'unavailable_count': 0,
        },
      ],
    });

    final headcount = MeetingHeadcount(result);

    expect(headcount.othersCountAt(headcount.grid.at(0, 0)!), 2);
  });

  test('날짜별은 하루 칸 안의 결과 칸 중 가장 적은 사람 수다', () {
    final meeting = makeMeeting(
      startDate: DateTime.utc(2027, 3, 1),
      endDate: DateTime.utc(2027, 3, 31),
      mode: MeetingMode.daily,
      startTime: '00:00:00',
      endTime: '00:00:00',
    );
    final day1 = [
      for (var slot = 0; slot < 48; slot++)
        (
          seoul(1, 0, slot * 30),
          seoul(1, 0, slot * 30 + 30),
          slot == 20 ? 1 : 2,
        ),
    ];
    final day2 = [
      for (var slot = 0; slot < 48; slot++)
        (seoul(2, 0, slot * 30), seoul(2, 0, slot * 30 + 30), 3),
    ];
    final headcount = MeetingHeadcount(resultOf(meeting, [...day1, ...day2]));
    final cells = headcount.grid.cells;

    expect(headcount.othersCountAt(cells[0]), 1);
    expect(headcount.othersCountAt(cells[1]), 3);
    expect(headcount.othersCountAt(cells[2]), 0);
  });

  test('다른 사람은 참여자 수 전체이고 내 칸은 없다', () {
    final headcount = MeetingHeadcount(
      resultOf(makeMeeting(), [(seoul(1, 6), seoul(1, 6, 30), 2)]),
    );

    expect(headcount.hasSelf, isFalse);
    expect(headcount.othersTotal, 3);
    expect(
      headcount.answerAt(headcount.grid.at(0, 0)!),
      MeetingAnswer.unanswered,
    );
  });

  test('참여자가 없으면 모든 칸이 0이다', () {
    final headcount = MeetingHeadcount(
      resultOf(makeMeeting(), const [], participants: 0),
    );

    expect(headcount.othersTotal, 0);
    expect(headcount.grid.cells.map(headcount.othersCountAt).toSet(), {0});
  });
}
