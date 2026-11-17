import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_brush.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

const yes = MeetingAnswer.available;
const no = MeetingAnswer.unavailable;
const blank = MeetingAnswer.unanswered;

/// 칸 자리마다 답. 없는 자리는 아직 답하지 않았다
MeetingAnswer Function(MeetingCell) answers(
  Map<(int, int), MeetingAnswer> places,
) =>
    (cell) => places[(cell.column, cell.row)] ?? blank;

/// 바뀐 칸을 자리로
Map<(int, int), MeetingAnswer> placesOf(
  Map<MeetingCell, MeetingAnswer> changes,
) => {
  for (final MapEntry(key: cell, value: answer) in changes.entries)
    (cell.column, cell.row): answer,
};

void main() {
  tz.initializeTimeZones();

  for (final (name, meeting) in [
    ('시간별(3월 1~5일, 6~18시 30분 칸)', makeMeeting()),
    (
      '날짜별(3월 1~10일)',
      makeMeeting(
        mode: MeetingMode.daily,
        endDate: DateTime.utc(2027, 3, 10),
        startTime: '00:00:00',
        endTime: '00:00:00',
      ),
    ),
    (
      '요일별(3월 1~7일)',
      makeMeeting(
        mode: MeetingMode.weekly,
        endDate: DateTime.utc(2027, 3, 7),
        startTime: '00:00:00',
        endTime: '00:00:00',
      ),
    ),
  ]) {
    group('$name: 답은 칠한 그대로다', () {
      final grid = MeetingGrid.of(meeting);
      final cells = grid.cells;

      Map<(int, int), MeetingAnswer> stroke(
        Map<(int, int), MeetingAnswer> before,
        List<MeetingCell> touched,
        MeetingAnswer brush, {
        bool clear = false,
      }) =>
          placesOf(brushStroke(answers(before), touched, brush, clear: clear));

      (int, int) at(int index) => (cells[index].column, cells[index].row);

      test('붓은 지나간 칸만 그 답으로 칠하고 나머지는 채우지 않는다', () {
        expect(stroke({}, [cells[0], cells[1]], no), {at(0): no, at(1): no});
        expect(stroke({}, [cells[2]], yes), {at(2): yes});
      });

      test('두 붓을 한 묶음 안에서 섞어 칠할 수 있다', () {
        final before = {at(0): yes, at(1): yes};
        expect(stroke(before, [cells[2], cells[3]], no), {
          at(2): no,
          at(3): no,
        });
      });

      test('다른 답의 칸은 덮어쓴다', () {
        final before = {at(0): yes, at(1): no};
        expect(stroke(before, [cells[0], cells[1], cells[2]], no), {
          at(0): no,
          at(2): no,
        });
      });

      test('붓의 답인 칸에서 시작하면 지나간 칸을 모두 답하지 않은 칸으로 지운다', () {
        final before = {at(0): no, at(1): yes, at(2): no};
        expect(
          stroke(
            before,
            [cells[0], cells[1], cells[2], cells[3]],
            no,
            clear: true,
          ),
          {at(0): blank, at(1): blank, at(2): blank},
        );
      });

      test('이미 그 답인 칸은 바뀐 칸에 넣지 않는다', () {
        expect(stroke({at(0): yes}, [cells[0]], yes), isEmpty);
      });
    });
  }

  group('시간별 날짜 머리', () {
    final grid = MeetingGrid.of(makeMeeting());
    final day = [
      for (final cell in grid.cells)
        if (cell.column == 1) cell,
    ];

    test('답하지 않은 날은 하루 전체를 가능으로 칠한다', () {
      final changes = brushDay(day, answers({}));
      expect(changes.keys, day);
      expect(changes.values.toSet(), {yes});
    });

    test('한 칸이라도 답한 날은 하루 전체를 지운다', () {
      for (final answer in [yes, no]) {
        final changes = brushDay(day, answers({(1, 5): answer}));
        expect(changes.keys, day);
        expect(changes.values.toSet(), {blank});
      }
    });
  });
}
