import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 같은 사람들이 되고 같은 사람들이 안 되는 이어진 칸 묶음. 선택된 일정 카드 하나다
@immutable
class MeetingRun {
  const MeetingRun(this.cells, this.people, [this.unavailable = const {}]);

  /// 화면 순서로 이어진 칸
  final List<MeetingCell> cells;

  /// 모든 칸에서 되는 참여자
  final Set<String> people;

  /// 모든 칸에서 안 된다고 한 참여자
  final Set<String> unavailable;

  MeetingCell get first => cells.first;

  MeetingCell get last => cells.last;

  /// 칸들의 실제 길이 합
  Duration get length =>
      cells.fold(Duration.zero, (sum, cell) => sum + cell.span.length);
}

/// [grid]에서 되는 사람들과 안 되는 사람들이 똑같은 이어진 칸을 묶는다. 되는 사람이 [minPeople]명 이상인
/// 묶음만 화면 순서로 돌려준다.
///
/// [peopleAt]은 칸마다 되는 참여자, [unavailableAt]은 칸마다 안 된다고 한 참여자다. 둘 중 한 사람이라도
/// 다르면 다른 묶음이라, 묶음의 안 되는 사람은 묶음 내내 안 된다고 한 사람이다.
///
/// 테스트: test/features/meeting/domain/meeting_runs_test.dart
List<MeetingRun> findMeetingRuns(
  MeetingGrid grid,
  Set<String> Function(MeetingCell cell) peopleAt, {
  Set<String> Function(MeetingCell cell)? unavailableAt,
  int minPeople = 2,
}) {
  final runs = <MeetingRun>[];
  var cells = <MeetingCell>[];
  var people = <String>{};
  var unavailable = <String>{};
  void close() {
    if (cells.isNotEmpty && people.length >= minPeople) {
      runs.add(MeetingRun(cells, people, unavailable));
    }
  }

  for (final cell in grid.cells) {
    final here = peopleAt(cell);
    final out = unavailableAt?.call(cell) ?? const <String>{};
    if (cells.isNotEmpty &&
        cell.joinsPrevious &&
        setEquals(here, people) &&
        setEquals(out, unavailable)) {
      cells.add(cell);
      continue;
    }
    close();
    cells = [cell];
    people = here;
    unavailable = out;
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

/// [first] 기준으로 정렬한다. 같으면 남은 기준을 차례로 보고, 앞의 기준이 같은 후보는 안 되는 사람이 적은
/// 쪽이 먼저다: 모모밋 추천은 점수 → 불가능 적은 순 → 인원 많은 순 → 긴 순 → 빠른 날짜 순, 인원 많은 순은
/// 인원 → 불가능 → 길이 → 날짜, 긴 순은 길이 → 인원 → 불가능 → 날짜, 날짜 순은 날짜 → 인원 → 길이다.
/// 모모밋 추천의 점수는 [mode]의 길이로 센다
List<MeetingRun> sortMeetingRuns(
  Iterable<MeetingRun> runs,
  MeetingRunOrder first, {
  required MeetingMode mode,
}) {
  int byDate(MeetingRun a, MeetingRun b) => a.first.index - b.first.index;
  int byPeople(MeetingRun a, MeetingRun b) => b.people.length - a.people.length;
  int byUnavailable(MeetingRun a, MeetingRun b) =>
      a.unavailable.length - b.unavailable.length;
  int byLength(MeetingRun a, MeetingRun b) => b.length.compareTo(a.length);
  int byScore(MeetingRun a, MeetingRun b) =>
      meetingRunScore(b, mode).compareTo(meetingRunScore(a, mode));
  final keys = switch (first) {
    MeetingRunOrder.recommended => [
      byScore,
      byUnavailable,
      byPeople,
      byLength,
      byDate,
    ],
    MeetingRunOrder.people => [byPeople, byUnavailable, byLength, byDate],
    MeetingRunOrder.length => [byLength, byPeople, byUnavailable, byDate],
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
