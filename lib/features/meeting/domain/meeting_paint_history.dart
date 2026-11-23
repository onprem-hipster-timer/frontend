import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';

/// 칠하기 한 걸음: 답이 바뀐 칸마다 칠하기 전([before])과 뒤([after])의 답
typedef _Step = ({
  Map<MeetingCell, MeetingAnswer> before,
  Map<MeetingCell, MeetingAnswer> after,
});

/// 내가 칠한 것의 되돌리기·다시 하기 기록. 한 걸음은 한 번에 넘긴 칠하기(끈 붓질 하나, 누른 칸 하나)다.
///
/// 답이 바뀌는 칸이 없는 칠하기는 남기지 않는다. 새 걸음을 남기면 다시 할 걸음은 버리고, 걸음이 [limit]개를
/// 넘으면 가장 오래된 것부터 버린다.
///
/// 테스트: test/features/meeting/domain/meeting_paint_history_test.dart
class MeetingPaintHistory {
  /// 되돌릴 수 있는 걸음 수
  static const limit = 100;

  final _done = <_Step>[];
  final _undone = <_Step>[];

  /// 칠하기 전 답이 [answerAt]일 때 [changes]로 칠한 것을 한 걸음으로 남긴다
  void record(
    Map<MeetingCell, MeetingAnswer> changes,
    MeetingAnswer Function(MeetingCell cell) answerAt,
  ) {
    final before = <MeetingCell, MeetingAnswer>{};
    final after = <MeetingCell, MeetingAnswer>{};
    for (final MapEntry(key: cell, value: answer) in changes.entries) {
      final was = answerAt(cell);
      if (was == answer) continue;
      before[cell] = was;
      after[cell] = answer;
    }
    if (after.isEmpty) return;
    _undone.clear();
    _done.add((before: before, after: after));
    if (_done.length > limit) _done.removeAt(0);
  }

  /// 마지막 걸음을 되돌리는 칠하기(칠하기 전 답). 되돌릴 걸음이 없으면 null
  Map<MeetingCell, MeetingAnswer>? undo() {
    if (_done.isEmpty) return null;
    final step = _done.removeLast();
    _undone.add(step);
    return step.before;
  }

  /// 마지막으로 되돌린 걸음을 다시 하는 칠하기. 다시 할 걸음이 없으면 null
  Map<MeetingCell, MeetingAnswer>? redo() {
    if (_undone.isEmpty) return null;
    final step = _undone.removeLast();
    _done.add(step);
    return step.after;
  }

  /// 모든 걸음을 버린다
  void clear() {
    _done.clear();
    _undone.clear();
  }
}
