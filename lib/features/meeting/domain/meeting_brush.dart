import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';

/// 붓([brush]: 가능 또는 불가능)으로 [cells]를 한 번 칠한 결과: 바뀌는 칸마다 새 답.
///
/// [clear]면 [cells]를 답하지 않은 칸으로 지우고, 아니면 [brush]로 칠한다. 불가능으로 칠할 때 그 단위
/// ([MeetingGrid.unitOf]: 시간별은 그날, 날짜별·요일별은 격자 전체)에 아직 답한 칸이 하나도 없으면 단위의 나머지
/// 칸을 가능으로 채운다. 한가한 날 안 되는 시간만 칠해도 그날 답이 끝나게 하려는 것이다.
///
/// [answerAt]은 칠하기 전 칸마다의 답이다.
///
/// 테스트: test/features/meeting/domain/meeting_brush_test.dart
Map<MeetingCell, MeetingAnswer> brushStroke(
  MeetingGrid grid,
  MeetingAnswer Function(MeetingCell cell) answerAt,
  Iterable<MeetingCell> cells,
  MeetingAnswer brush, {
  required bool clear,
}) {
  final painted = clear ? MeetingAnswer.unanswered : brush;
  final changes = {for (final cell in cells) cell: painted};
  if (painted != MeetingAnswer.unavailable) return changes;
  final units = <MeetingCell, List<MeetingCell>>{};
  for (final cell in cells) {
    final unit = grid.unitOf(cell);
    units.putIfAbsent(unit.first, () => unit);
  }
  for (final unit in units.values) {
    if (unit.any((cell) => answerAt(cell) != MeetingAnswer.unanswered)) {
      continue;
    }
    for (final cell in unit) {
      changes.putIfAbsent(cell, () => MeetingAnswer.available);
    }
  }
  return changes;
}

/// 붓으로 [cells](하루 전체 등)를 한 번에 칠한 결과. 모두 이미 [brush]면 지우고, 아니면 [brush]로 칠한다
Map<MeetingCell, MeetingAnswer> brushAll(
  MeetingGrid grid,
  MeetingAnswer Function(MeetingCell cell) answerAt,
  List<MeetingCell> cells,
  MeetingAnswer brush,
) => brushStroke(
  grid,
  answerAt,
  cells,
  brush,
  clear: cells.every((cell) => answerAt(cell) == brush),
);
