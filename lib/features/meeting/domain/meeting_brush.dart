import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';

/// 붓([brush]: 가능 또는 불가능)으로 [cells]를 한 번 칠한 결과: 바뀌는 칸마다 새 답.
///
/// [clear]는 붓질을 시작한 칸이 이미 붓의 답이었는지다. 그러면 이 붓질은 반대로 한다(한 붓으로 되돌린다).
///
/// 칠하는 방식은 묶음([MeetingGrid.groupOf]: 시간별은 하루, 날짜별·요일별은 모임 전체)마다 하나다. 아직 답하지
/// 않은 묶음은 첫 붓질이 방식을 정한다.
/// - 가능으로 칠한 묶음: 칠한 칸만 되고 나머지는 안 된다(저장하지 않는다). 가능 붓이 칸을 더하고, 가능 칸에서
///   시작하면 지운다. 남은 칸이 없으면 다시 답하지 않은 묶음이다.
/// - 불가능으로 칠한 묶음: 칠한 칸은 안 되고 나머지는 모두 된다. 불가능 붓이 안 되는 칸을 더하고, 불가능 칸에서
///   시작하면 되는 칸으로 돌린다.
///
/// 다른 방식으로 칠한 묶음에는 붓이 아무것도 바꾸지 않고 그 묶음을 [MeetingStroke.blocked]로 알린다(초기화한 뒤
/// 다른 방식으로 칠한다).
///
/// 붓질이 지난 묶음에 안 되는 칸이 있으면 그 묶음의 비어 있는 칸을 모두 되는 칸으로 채운다(묶음 전체를 덮어
/// 저장한다). 여러 날에 걸친 시간별 붓질은 날마다 따로 이 규칙을 따른다.
///
/// [answerAt]은 칠하기 전 칸마다의 답이다.
///
/// 테스트: test/features/meeting/domain/meeting_brush_test.dart
MeetingStroke brushStroke(
  MeetingGrid grid,
  MeetingAnswer Function(MeetingCell cell) answerAt,
  Iterable<MeetingCell> cells,
  MeetingAnswer brush, {
  required bool clear,
}) {
  final touched = <MeetingCell, List<MeetingCell>>{};
  for (final cell in cells) {
    touched.putIfAbsent(grid.groupOf(cell).first, () => []).add(cell);
  }
  final changes = <MeetingCell, MeetingAnswer>{};
  final blocked = <List<MeetingCell>>[];
  for (final groupCells in touched.values) {
    final group = grid.groupOf(groupCells.first);
    final style = _styleOf(group, answerAt);
    if (style != MeetingAnswer.unanswered && style != brush) {
      blocked.add(group);
      continue;
    }
    final next = switch (style) {
      MeetingAnswer.unanswered => clear ? null : brush,
      MeetingAnswer.available => clear ? MeetingAnswer.unanswered : brush,
      MeetingAnswer.unavailable => clear ? MeetingAnswer.available : brush,
    };
    if (next == null) continue;
    for (final cell in groupCells) {
      changes[cell] = next;
    }
    changes.addAll(_cover(group, (cell) => changes[cell] ?? answerAt(cell)));
  }
  return (changes: changes, blocked: blocked);
}

/// 붓질 한 번의 결과: 바뀌는 칸마다 새 답과, 다른 방식으로 칠한 묶음이라 바꾸지 않은 묶음(묶음의 칸들, 붓질 순서)
typedef MeetingStroke = ({
  Map<MeetingCell, MeetingAnswer> changes,
  List<List<MeetingCell>> blocked,
});

/// 묶음 전체를 한 번에 칠한 결과: 답하지 않은 묶음이면 모두 되는 칸으로, 답한 묶음이면 모두 지운다.
/// 시간별 날짜 머리(그날)와 날짜별·요일별 '모두 지우기'가 쓴다
Map<MeetingCell, MeetingAnswer> brushGroup(
  List<MeetingCell> group,
  MeetingAnswer Function(MeetingCell cell) answerAt,
) {
  final answer = _styleOf(group, answerAt) == MeetingAnswer.unanswered
      ? MeetingAnswer.available
      : MeetingAnswer.unanswered;
  return {for (final cell in group) cell: answer};
}

/// 안 되는 칸이 있는데 비어 있는 칸이 남은 묶음(다른 곳에서 저장한 값, 방식이 바뀐 모임 등)을 묶음 전체를 덮게
/// 채운 칸. 저장하기 전에 더한다. backend는 안 되는 구간이 있는 묶음을 미팅 날짜의 하루 범위로 모두 덮어야 받는다
Map<MeetingCell, MeetingAnswer> coverUnavailableGroups(
  MeetingGrid grid,
  MeetingAnswer Function(MeetingCell cell) answerAt,
) {
  final groups = {for (final cell in grid.cells) grid.groupOf(cell).first};
  return {for (final first in groups) ..._cover(grid.groupOf(first), answerAt)};
}

/// 묶음의 방식: 안 되는 칸이 있으면 불가능, 되는 칸만 있으면 가능, 없으면 미답
MeetingAnswer _styleOf(
  List<MeetingCell> day,
  MeetingAnswer Function(MeetingCell cell) answerAt,
) {
  var style = MeetingAnswer.unanswered;
  for (final cell in day) {
    switch (answerAt(cell)) {
      case MeetingAnswer.unavailable:
        return MeetingAnswer.unavailable;
      case MeetingAnswer.available:
        style = MeetingAnswer.available;
      case MeetingAnswer.unanswered:
        break;
    }
  }
  return style;
}

/// 안 되는 칸이 있는 [group]의 비어 있는 칸을 되는 칸으로
Map<MeetingCell, MeetingAnswer> _cover(
  List<MeetingCell> group,
  MeetingAnswer Function(MeetingCell cell) answerAt,
) => group.any((cell) => answerAt(cell) == MeetingAnswer.unavailable)
    ? {
        for (final cell in group)
          if (answerAt(cell) == MeetingAnswer.unanswered)
            cell: MeetingAnswer.available,
      }
    : const {};
