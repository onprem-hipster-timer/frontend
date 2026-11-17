import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 같은 사람들이 되는 이어진 칸 묶음. 선택된 일정 카드 하나다
@immutable
class MeetingRun {
  const MeetingRun(this.cells, this.people);

  /// 화면 순서로 이어진 칸
  final List<MeetingCell> cells;

  /// 모든 칸에서 되는 참여자
  final Set<String> people;

  MeetingCell get first => cells.first;

  MeetingCell get last => cells.last;

  /// 칸들의 실제 길이 합
  Duration get length =>
      cells.fold(Duration.zero, (sum, cell) => sum + cell.span.length);
}

/// [grid]에서 되는 사람들이 똑같은 이어진 칸을 묶는다. [minPeople]명 이상인 묶음만 화면 순서로 돌려준다.
///
/// [peopleAt]은 칸마다 되는 참여자다. 사람이 하나라도 다르면 다른 묶음이다.
///
/// 테스트: test/features/meeting/domain/meeting_runs_test.dart
List<MeetingRun> findMeetingRuns(
  MeetingGrid grid,
  Set<String> Function(MeetingCell cell) peopleAt, {
  int minPeople = 2,
}) {
  final runs = <MeetingRun>[];
  var cells = <MeetingCell>[];
  var people = <String>{};
  void close() {
    if (cells.isNotEmpty && people.length >= minPeople) {
      runs.add(MeetingRun(cells, people));
    }
  }

  for (final cell in grid.cells) {
    final here = peopleAt(cell);
    if (cells.isNotEmpty && cell.joinsPrevious && setEquals(here, people)) {
      cells.add(cell);
      continue;
    }
    close();
    cells = [cell];
    people = here;
  }
  close();
  return runs;
}

/// 추천 시간의 첫 정렬 기준
enum MeetingRunOrder {
  /// 모모밋 추천: 많이 모이면서 오래 되는 순([meetingRunScore]가 높은 순)
  recommended,

  /// 빠른 날짜(요일별은 월요일부터)
  date,

  /// 되는 사람이 많은 순
  people,

  /// 긴 순
  length,
}

/// 모모밋 추천 점수: 되는 인원 × 길이. 길이는 시간별이면 시간, 날짜별·요일별이면 날 수다
double meetingRunScore(MeetingRun run, MeetingMode mode) {
  final length = mode == MeetingMode.hourly
      ? run.length.inMinutes / 60
      : run.cells.length.toDouble();
  return run.people.length * length;
}

/// [first] 기준으로 정렬한다. 같으면 인원 많은 순 → 긴 순 → 빠른 날짜 순의 남은 기준을 차례로 본다.
/// 모모밋 추천의 점수는 [mode]의 길이로 센다
List<MeetingRun> sortMeetingRuns(
  Iterable<MeetingRun> runs,
  MeetingRunOrder first, {
  required MeetingMode mode,
}) {
  int byDate(MeetingRun a, MeetingRun b) => a.first.index - b.first.index;
  int byPeople(MeetingRun a, MeetingRun b) => b.people.length - a.people.length;
  int byLength(MeetingRun a, MeetingRun b) => b.length.compareTo(a.length);
  int byScore(MeetingRun a, MeetingRun b) =>
      meetingRunScore(b, mode).compareTo(meetingRunScore(a, mode));
  final keys = switch (first) {
    MeetingRunOrder.recommended => [byScore, byPeople, byLength, byDate],
    MeetingRunOrder.people => [byPeople, byLength, byDate],
    MeetingRunOrder.length => [byLength, byPeople, byDate],
    MeetingRunOrder.date => [byDate, byPeople, byLength],
  };
  return runs.toList()..sort((a, b) {
    for (final compare in keys) {
      final order = compare(a, b);
      if (order != 0) return order;
    }
    return 0;
  });
}
