import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

DateTime march(int day) => DateTime.utc(2027, 3, day);

/// 3월 1~5일 6~18시 30분 칸의 시간별 격자
MeetingGrid hourly() => MeetingGrid.of(makeMeeting());

/// (열, 줄) 자리마다 되는 사람. 적지 않은 칸은 아무도 안 된다
Set<String> Function(MeetingCell) peopleBy(Map<(int, int), Set<String>> map) =>
    (cell) => map[(cell.column, cell.row)] ?? const {};

/// 칸 자리 목록
List<(int, int)> placesOf(MeetingRun run) => [
  for (final cell in run.cells) (cell.column, cell.row),
];

void main() {
  setUpAll(tz.initializeTimeZones);

  group('묶기', () {
    test('맞닿은 칸에 같은 사람들이 되면 하나로 묶는다', () {
      final runs = findMeetingRuns(
        hourly(),
        peopleBy({
          (0, 2): {'a', 'b'},
          (0, 3): {'b', 'a'},
          (0, 4): {'a', 'b'},
        }),
      );

      expect(runs, hasLength(1));
      expect(placesOf(runs.single), [(0, 2), (0, 3), (0, 4)]);
      expect(runs.single.people, {'a', 'b'});
      expect(runs.single.length, const Duration(minutes: 90));
    });

    test('사이에 빈 칸이 있으면 같은 사람들이어도 따로 묶는다', () {
      final runs = findMeetingRuns(
        hourly(),
        peopleBy({
          (0, 2): {'a', 'b'},
          (0, 4): {'a', 'b'},
        }),
      );

      expect(
        [for (final run in runs) placesOf(run)],
        [
          [(0, 2)],
          [(0, 4)],
        ],
      );
    });

    test('사람이 하나라도 다르면 맞닿아도 따로 묶는다', () {
      final runs = findMeetingRuns(
        hourly(),
        peopleBy({
          (0, 0): {'a', 'b', 'c'},
          (0, 1): {'a', 'b'},
          (0, 2): {'a', 'c'},
        }),
      );

      expect(
        [for (final run in runs) run.people],
        [
          {'a', 'b', 'c'},
          {'a', 'b'},
          {'a', 'c'},
        ],
      );
    });

    test('시간별은 앞 날의 마지막 칸과 다음 날 첫 칸을 잇지 않는다', () {
      final runs = findMeetingRuns(
        hourly(),
        peopleBy({
          (0, 23): {'a', 'b'},
          (1, 0): {'a', 'b'},
        }),
      );

      expect(runs, hasLength(2));
    });

    test('날짜별은 이어지는 날을 자정을 넘어 하나로 묶는다', () {
      final grid = MeetingGrid.of(
        makeMeeting(
          startDate: march(1),
          endDate: march(10),
          availableDays: [0, 1, 2, 3, 4, 5, 6],
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
      );
      final both = {'a', 'b'};
      final runs = findMeetingRuns(grid, (cell) {
        final day = cell.day.day;
        return day >= 6 && day <= 8 ? both : const {};
      });

      expect(runs, hasLength(1));
      expect([for (final cell in runs.single.cells) cell.day.day], [6, 7, 8]);
      expect(runs.single.length, const Duration(days: 3));
      expect(
        grid.spanOf(runs.single.cells).length,
        const Duration(days: 3),
        reason: '토요일(6일)에서 일요일(7일)로 넘어가 달력 줄이 바뀌어도 이어진다',
      );
    });

    test('요일별은 기간의 날짜 순서와 상관없이 이웃한 요일을 묶는다', () {
      // 3월 3일(수)~9일(화): 화요일(9일)과 수요일(3일)은 날짜로는 떨어져 있다
      final grid = MeetingGrid.of(
        makeMeeting(
          startDate: march(3),
          endDate: march(9),
          availableDays: [0, 1, 2, 3, 4, 5, 6],
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
      );
      final runs = findMeetingRuns(
        grid,
        peopleBy({
          (1, 0): {'a', 'b'},
          (2, 0): {'a', 'b'},
        }),
      );

      expect(placesOf(runs.single), [(1, 0), (2, 0)]);
    });

    test('한 명만 되는 칸은 묶지 않아 참여자가 하나면 카드가 없다', () {
      final runs = findMeetingRuns(
        hourly(),
        (cell) => cell.row < 4 ? {'a'} : const {},
      );

      expect(runs, isEmpty);
    });

    test('칸이 없는 모임은 묶음도 없다', () {
      final grid = MeetingGrid.of(
        makeMeeting(
          startDate: march(1),
          endDate: march(2),
          availableDays: [5],
          startTime: '00:00:00',
          endTime: '00:00:00',
        ),
      );

      expect(findMeetingRuns(grid, (_) => {'a', 'b'}), isEmpty);
    });

    test('마지막 칸에서 끝나는 묶음도 돌려준다', () {
      final runs = findMeetingRuns(
        hourly(),
        peopleBy({
          (4, 22): {'a', 'b'},
          (4, 23): {'a', 'b'},
        }),
      );

      expect(placesOf(runs.single), [(4, 22), (4, 23)]);
    });
  });

  group('정렬', () {
    // 날짜 순: A(3명·1시간) B(2명·2시간) C(3명·2시간) D(2명·2시간) E(3명·2시간)
    late List<MeetingRun> runs;

    setUp(() {
      final abc = {'a', 'b', 'c'};
      final ab = {'a', 'b'};
      final ac = {'a', 'c'};
      final bc = {'b', 'c'};
      runs = findMeetingRuns(
        hourly(),
        peopleBy({
          for (final row in [0, 1]) (0, row): abc,
          for (final row in [4, 5, 6, 7]) (0, row): ab,
          for (final row in [10, 11, 12, 13]) (0, row): abc,
          for (final row in [0, 1, 2, 3]) (1, row): ac,
          for (final row in [0, 1, 2, 3]) (2, row): {...abc},
          for (final row in [6]) (2, row): bc,
        }),
      );
    });

    String name(MeetingRun run) => switch ((run.first.column, run.first.row)) {
      (0, 0) => 'A',
      (0, 4) => 'B',
      (0, 10) => 'C',
      (1, 0) => 'D',
      (2, 0) => 'E',
      (2, 6) => 'F',
      _ => '?',
    };

    test('기본(인원 많은 순)은 인원이 같으면 긴 순, 그다음 빠른 날짜 순이다', () {
      expect(sortMeetingRuns(runs, MeetingRunOrder.people).map(name), [
        'C',
        'E',
        'A',
        'B',
        'D',
        'F',
      ]);
    });

    test('시간 긴 순은 길이가 같으면 인원 많은 순, 그다음 빠른 날짜 순이다', () {
      expect(sortMeetingRuns(runs, MeetingRunOrder.length).map(name), [
        'C',
        'E',
        'B',
        'D',
        'A',
        'F',
      ]);
    });

    test('날짜 순은 화면 순서다', () {
      expect(sortMeetingRuns(runs, MeetingRunOrder.date).map(name), [
        'A',
        'B',
        'C',
        'D',
        'E',
        'F',
      ]);
    });

    test('들어온 순서가 달라도 결과가 같다', () {
      final reversed = runs.reversed.toList();
      for (final order in MeetingRunOrder.values) {
        expect(
          sortMeetingRuns(reversed, order).map(name),
          sortMeetingRuns(runs, order).map(name),
        );
      }
    });
  });
}
