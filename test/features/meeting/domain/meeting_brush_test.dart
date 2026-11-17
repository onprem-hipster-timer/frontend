import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_brush.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

const available = MeetingAnswer.available;
const unavailable = MeetingAnswer.unavailable;
const unanswered = MeetingAnswer.unanswered;

/// 칸 자리마다 답. 없는 자리는 아직 답하지 않았다
MeetingAnswer Function(MeetingCell) answers(
  Map<(int, int), MeetingAnswer> places,
) =>
    (cell) => places[(cell.column, cell.row)] ?? unanswered;

/// 바뀐 칸을 자리로
Map<(int, int), MeetingAnswer> placesOf(
  Map<MeetingCell, MeetingAnswer> changes,
) => {
  for (final MapEntry(key: cell, value: answer) in changes.entries)
    (cell.column, cell.row): answer,
};

void main() {
  tz.initializeTimeZones();

  group('시간별(3월 1~5일, 6~18시 30분 칸)', () {
    final grid = MeetingGrid.of(makeMeeting());
    List<MeetingCell> column(int column, Iterable<int> rows) => [
      for (final row in rows) grid.at(column, row)!,
    ];

    test('가능으로 칠하면 그 칸만 가능이 된다', () {
      final changes = brushStroke(
        grid,
        answers({}),
        column(0, [0, 1]),
        available,
        clear: false,
      );

      expect(placesOf(changes), {(0, 0): available, (0, 1): available});
    });

    test('지우면 그 칸만 답하지 않은 칸이 된다', () {
      final changes = brushStroke(
        grid,
        answers({(0, 0): unavailable, (0, 1): unavailable}),
        column(0, [0, 1]),
        unavailable,
        clear: true,
      );

      expect(placesOf(changes), {(0, 0): unanswered, (0, 1): unanswered});
    });

    test('아무것도 답하지 않은 날에 불가능을 칠하면 그날 나머지 칸은 가능이 된다', () {
      final changes = brushStroke(
        grid,
        answers({(1, 3): available}),
        column(0, [4, 5]),
        unavailable,
        clear: false,
      );

      expect(changes, hasLength(grid.rows), reason: '3월 1일 열만 바뀐다');
      expect(changes[grid.at(0, 4)], unavailable);
      expect(changes[grid.at(0, 5)], unavailable);
      expect(changes[grid.at(0, 0)], available);
      expect(changes[grid.at(0, 23)], available);
      expect(changes.containsKey(grid.at(1, 3)), isFalse);
    });

    test('이미 답한 칸이 있는 날에 불가능을 칠하면 그 칸만 바뀐다', () {
      for (final answered in [available, unavailable]) {
        final changes = brushStroke(
          grid,
          answers({(0, 10): answered}),
          column(0, [4]),
          unavailable,
          clear: false,
        );

        expect(placesOf(changes), {(0, 4): unavailable}, reason: '$answered');
      }
    });

    test('칠하는 칸 자신이 답한 칸이면 그날은 답한 날이라 채우지 않는다', () {
      final changes = brushStroke(
        grid,
        answers({(0, 4): available}),
        column(0, [4]),
        unavailable,
        clear: false,
      );

      expect(placesOf(changes), {(0, 4): unavailable});
    });

    test('여러 날에 걸쳐 칠하면 답하지 않은 날만 채운다', () {
      final changes = brushStroke(
        grid,
        answers({(1, 20): available}),
        [
          ...column(0, [2]),
          ...column(1, [2]),
        ],
        unavailable,
        clear: false,
      );

      expect(changes, hasLength(grid.rows + 1));
      expect(changes[grid.at(0, 0)], available);
      expect(changes[grid.at(1, 2)], unavailable);
      expect(changes.containsKey(grid.at(1, 0)), isFalse);
    });

    test('불가능을 지울 때와 가능을 칠할 때는 채우지 않는다', () {
      expect(
        brushStroke(grid, answers({}), column(0, [4]), available, clear: false),
        hasLength(1),
      );
      expect(
        brushStroke(
          grid,
          answers({(0, 4): unavailable}),
          column(0, [4]),
          unavailable,
          clear: true,
        ),
        hasLength(1),
      );
    });

    test('하루 전체를 칠하면 다른 날은 그대로다', () {
      final day = grid.unitOf(grid.at(2, 7)!);

      expect(day, hasLength(grid.rows));
      expect(day.every((cell) => cell.column == 2), isTrue);
    });
  });

  group('날짜별·요일별은 격자 전체가 한 단위다', () {
    MeetingGrid gridOf(MeetingMode mode) => MeetingGrid.of(
      makeMeeting(
        endDate: DateTime.utc(2027, 3, 7),
        mode: mode,
        startTime: '00:00:00',
        endTime: '00:00:00',
      ),
    );

    for (final mode in [MeetingMode.daily, MeetingMode.weekly]) {
      test('$mode: 아무 날도 답하지 않았을 때 불가능을 칠하면 나머지 날이 모두 가능이 된다', () {
        final grid = gridOf(mode);
        final tuesday = grid.cells.firstWhere((cell) => cell.day.day == 2);
        final changes = brushStroke(
          grid,
          answers({}),
          [tuesday],
          unavailable,
          clear: false,
        );

        expect(changes, hasLength(7));
        expect(changes[tuesday], unavailable);
        expect(
          changes.entries.where((e) => e.value == available),
          hasLength(6),
        );
      });

      test('$mode: 한 날이라도 답했으면 칠한 날만 바뀐다', () {
        final grid = gridOf(mode);
        final changes = brushStroke(
          grid,
          answers({(grid.cells.last.column, grid.cells.last.row): available}),
          [grid.cells.first],
          unavailable,
          clear: false,
        );

        expect(changes, {grid.cells.first: unavailable});
      });
    }
  });
}
