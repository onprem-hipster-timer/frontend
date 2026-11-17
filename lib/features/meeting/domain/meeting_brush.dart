import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';

/// 붓([brush]: 가능 또는 불가능)으로 [cells]를 한 번 칠한 결과: 바뀌는 칸마다 새 답.
///
/// 답은 칠한 그대로다. 붓은 지나간 칸만 붓의 답으로 칠하고(다른 답이면 덮어쓴다) 나머지 칸은 건드리지 않는다.
/// 두 붓을 한 날·한 모임 안에서 섞어 쓸 수 있다. [clear]는 붓질을 시작한 칸이 이미 붓의 답이었는지다. 그러면
/// 지나간 칸을 모두 답하지 않은 칸으로 지운다. 이미 그 답인 칸은 결과에 넣지 않는다.
///
/// [answerAt]은 칠하기 전 칸마다의 답이다.
///
/// 테스트: test/features/meeting/domain/meeting_brush_test.dart
Map<MeetingCell, MeetingAnswer> brushStroke(
  MeetingAnswer Function(MeetingCell cell) answerAt,
  Iterable<MeetingCell> cells,
  MeetingAnswer brush, {
  required bool clear,
}) {
  final next = clear ? MeetingAnswer.unanswered : brush;
  return {
    for (final cell in cells)
      if (answerAt(cell) != next) cell: next,
  };
}

/// 시간별 날짜 머리로 하루([day])를 한 번에 칠한 결과: 답하지 않은 날이면 하루 전체를 되는 칸으로, 한 칸이라도
/// 답한 날이면 하루 전체를 지운다
Map<MeetingCell, MeetingAnswer> brushDay(
  List<MeetingCell> day,
  MeetingAnswer Function(MeetingCell cell) answerAt,
) {
  final answer = day.every((cell) => answerAt(cell) == MeetingAnswer.unanswered)
      ? MeetingAnswer.available
      : MeetingAnswer.unanswered;
  return {for (final cell in day) cell: answer};
}
