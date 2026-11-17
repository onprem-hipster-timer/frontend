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

  group('시간별(3월 1~5일, 6~18시 30분 칸): 하루마다 방식이 하나다', () {
    final grid = MeetingGrid.of(makeMeeting());
    List<MeetingCell> cells(int column, Iterable<int> rows) => [
      for (final row in rows) grid.at(column, row)!,
    ];
    Map<(int, int), MeetingAnswer> wholeDay(int column, MeetingAnswer answer) =>
        {for (var row = 0; row < grid.rows; row++) (column, row): answer};

    MeetingStroke stroke(
      Map<(int, int), MeetingAnswer> before,
      List<MeetingCell> cells,
      MeetingAnswer brush, {
      bool clear = false,
    }) => brushStroke(grid, answers(before), cells, brush, clear: clear);

    test('답하지 않은 날에 가능을 칠하면 칠한 칸만 가능이다', () {
      final result = stroke({}, cells(0, [0, 1]), yes);

      expect(placesOf(result.changes), {(0, 0): yes, (0, 1): yes});
      expect(result.blocked, isEmpty);
    });

    test('답하지 않은 날에 불가능을 칠하면 그 칸은 불가능, 그날 나머지는 모두 가능이다', () {
      final changes = stroke({(1, 3): yes}, cells(0, [4, 5]), no).changes;

      expect(changes, hasLength(grid.rows), reason: '3월 1일 열만 바뀐다');
      expect(changes[grid.at(0, 4)], no);
      expect(changes[grid.at(0, 5)], no);
      expect(changes[grid.at(0, 0)], yes);
      expect(changes[grid.at(0, 23)], yes);
      expect(changes.containsKey(grid.at(1, 3)), isFalse);
    });

    test('가능으로 표시한 날: 가능 붓은 더하고, 가능 칸에서 시작하면 지운다', () {
      final before = {(0, 2): yes, (0, 3): yes};

      expect(placesOf(stroke(before, cells(0, [4]), yes).changes), {
        (0, 4): yes,
      });
      expect(
        placesOf(stroke(before, cells(0, [3, 4]), yes, clear: true).changes),
        {(0, 3): blank, (0, 4): blank},
      );
    });

    test('가능으로 표시한 날에 불가능 붓은 아무것도 바꾸지 않고 그날을 막힌 날로 알린다', () {
      final result = stroke({(0, 2): yes}, cells(0, [2, 3]), no);

      expect(result.changes, isEmpty);
      expect(result.blocked.single.map((cell) => cell.column).toSet(), {0});
      expect(result.blocked.single, hasLength(grid.rows));
    });

    test('불가능으로 표시한 날: 불가능 붓은 더하고, 불가능 칸에서 시작하면 되는 칸으로 돌린다', () {
      final before = {...wholeDay(0, yes), (0, 4): no, (0, 5): no};

      expect(placesOf(stroke(before, cells(0, [6]), no).changes), {(0, 6): no});
      expect(
        placesOf(stroke(before, cells(0, [5, 6]), no, clear: true).changes),
        {(0, 5): yes, (0, 6): yes},
      );
    });

    test('불가능으로 표시한 날에 가능 붓은 아무것도 바꾸지 않고 막힌 날로 알린다', () {
      final before = {...wholeDay(0, yes), (0, 4): no};
      final result = stroke(before, cells(0, [4]), yes);

      expect(result.changes, isEmpty);
      expect(result.blocked, hasLength(1));
    });

    test('불가능 칸을 모두 되돌리면 그날은 모두 가능으로 남는다', () {
      final before = {...wholeDay(0, yes), (0, 4): no};
      final after = {
        ...before,
        ...placesOf(stroke(before, cells(0, [4]), no, clear: true).changes),
      };

      expect(after.values.toSet(), {yes});
    });

    test('답하지 않은 날에서 시작한 지우기 붓질은 그날을 바꾸지 않는다', () {
      final result = stroke({}, cells(2, [0]), yes, clear: true);

      expect(result.changes, isEmpty);
      expect(result.blocked, isEmpty);
    });

    test('여러 날에 걸친 붓질은 되는 날에만 칠하고 막힌 날은 붓질 순서로 모두 알린다', () {
      final before = {
        (1, 0): yes,
        ...wholeDay(2, yes),
        (2, 9): no,
        (3, 1): yes,
      };
      final result = stroke(before, [
        ...cells(0, [3]),
        ...cells(1, [3]),
        ...cells(2, [3]),
        ...cells(3, [3]),
      ], no);

      expect(result.changes[grid.at(0, 3)], no, reason: '빈 날은 불가능으로 시작');
      expect(result.changes[grid.at(0, 0)], yes, reason: '빈 날의 나머지는 가능');
      expect(result.changes[grid.at(2, 3)], no, reason: '불가능으로 표시한 날은 더하기');
      expect(result.changes.containsKey(grid.at(1, 3)), isFalse);
      expect(result.changes.containsKey(grid.at(3, 3)), isFalse);
      expect([for (final day in result.blocked) day.first.column], [1, 3]);
    });

    test('불가능 칸과 빈 칸이 섞인 날(다른 곳에서 저장한 값)은 그날을 칠하면 빈 칸을 가능으로 채운다', () {
      final changes = stroke({(0, 1): no}, cells(0, [3]), no).changes;

      expect(changes[grid.at(0, 3)], no);
      expect(changes[grid.at(0, 0)], yes);
      expect(changes[grid.at(0, 23)], yes);
      expect(changes.containsKey(grid.at(0, 1)), isFalse);
    });

    test('날짜 머리: 답하지 않은 날은 하루 전체를 가능으로, 답한 날은 지운다', () {
      final day = grid.groupOf(grid.at(2, 7)!);
      expect(day, hasLength(grid.rows));
      expect(day.every((cell) => cell.column == 2), isTrue);

      expect(brushGroup(day, answers({})).values.toSet(), {yes});
      expect(brushGroup(day, answers({(2, 4): no})).values.toSet(), {blank});
      expect(brushGroup(day, answers({(2, 4): yes})).values.toSet(), {blank});
    });

    test('저장 전에는 안 되는 칸이 있는 날의 빈 칸만 가능으로 덮는다', () {
      final cover = coverUnavailableGroups(
        grid,
        answers({(0, 1): no, (1, 1): yes}),
      );

      expect(cover, hasLength(grid.rows - 1));
      expect(cover.keys.every((cell) => cell.column == 0), isTrue);
      expect(cover.values.toSet(), {yes});
    });
  });

  group('날짜별·요일별은 모임 전체가 한 방식이다', () {
    for (final mode in [MeetingMode.daily, MeetingMode.weekly]) {
      final grid = MeetingGrid.of(
        makeMeeting(
          endDate: DateTime.utc(2027, 3, 7),
          mode: mode,
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
      );
      MeetingCell day(int date) =>
          grid.cells.firstWhere((cell) => cell.day.day == date);
      (int, int) at(int date) => (day(date).column, day(date).row);
      final everyDay = {
        for (final cell in grid.cells) (cell.column, cell.row): yes,
      };

      test('$mode: 아무 날도 답하지 않았을 때 불가능을 칠하면 나머지 날이 모두 가능이 된다', () {
        final changes = brushStroke(
          grid,
          answers({}),
          [day(2)],
          no,
          clear: false,
        ).changes;

        expect(changes, hasLength(7));
        expect(changes[day(2)], no);
        expect(changes.values.where((answer) => answer == yes), hasLength(6));
      });

      test('$mode: 가능으로 표시한 모임에 불가능 붓은 아무것도 바꾸지 않고 모임 전체를 막힌 묶음으로 알린다', () {
        final result = brushStroke(
          grid,
          answers({at(1): yes, at(3): yes}),
          [day(3), day(5)],
          no,
          clear: false,
        );

        expect(result.changes, isEmpty);
        expect(result.blocked.single, hasLength(7));
      });

      test('$mode: 불가능으로 표시한 모임은 불가능 칸에서 시작하면 되는 날로 돌린다', () {
        final before = {...everyDay, at(4): no};

        expect(
          brushStroke(grid, answers(before), [day(4)], no, clear: true).changes,
          {day(4): yes},
        );
      });

      test('$mode: 초기화는 답한 모임을 모두 빈 날로 돌린다', () {
        expect(brushGroup(grid.cells, answers({at(1): no})).values.toSet(), {
          blank,
        });
      });

      test('$mode: 저장 전에는 안 되는 날이 있으면 빈 날을 모두 가능으로 덮는다', () {
        final cover = coverUnavailableGroups(
          grid,
          answers({at(1): no, at(2): yes}),
        );

        expect(cover, hasLength(5));
        expect(cover.values.toSet(), {yes});
      });
    }
  });
}
