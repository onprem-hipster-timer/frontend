import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_paint_history.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

const yes = MeetingAnswer.available;
const no = MeetingAnswer.unavailable;
const blank = MeetingAnswer.unanswered;

void main() {
  tz.initializeTimeZones();

  // 3월 1일 6:00, 6:30, 7:00 칸
  final grid = MeetingGrid.of(makeMeeting());
  final a = grid.at(0, 0)!;
  final b = grid.at(0, 1)!;
  final c = grid.at(0, 2)!;

  late MeetingPaintHistory history;

  /// 화면의 내 칸. 없는 칸은 답하지 않았다
  late Map<MeetingCell, MeetingAnswer> shown;

  setUp(() {
    history = MeetingPaintHistory();
    shown = {};
  });

  MeetingAnswer answerAt(MeetingCell cell) => shown[cell] ?? blank;

  /// 화면처럼 칠하기 전 답으로 한 걸음을 남기고 칠한다
  void paint(Map<MeetingCell, MeetingAnswer> changes) {
    history.record(changes, answerAt);
    shown.addAll(changes);
  }

  /// 되돌리기·다시 하기가 내놓은 칠하기를 칠한다
  void apply(Map<MeetingCell, MeetingAnswer>? changes) {
    expect(changes, isNotNull);
    shown.addAll(changes!);
  }

  test('되돌리면 나중에 칠한 것부터 그 걸음의 칠하기 전 답을 내놓고, 다 되돌리면 null이다', () {
    paint({a: yes});
    paint({a: no, b: yes});

    final last = history.undo();
    expect(last, {a: yes, b: blank});
    apply(last);
    final first = history.undo();
    expect(first, {a: blank});
    apply(first);

    expect(history.undo(), isNull);
    expect(shown, {a: blank, b: blank});
  });

  test('다시 하면 되돌린 반대 차례로 그 걸음의 칠한 답을 내놓는다', () {
    paint({a: yes});
    paint({a: no, b: yes});
    apply(history.undo());
    apply(history.undo());

    expect(history.redo(), {a: yes});
    expect(history.redo(), {a: no, b: yes});
    expect(history.redo(), isNull);
  });

  test('되돌린 뒤 새로 칠하면 다시 할 걸음을 버리고 새 걸음부터 되돌린다', () {
    paint({a: yes});
    paint({b: yes});
    apply(history.undo());
    paint({c: no});

    expect(history.redo(), isNull);
    expect(history.undo(), {c: blank});
    expect(history.undo(), {a: blank});
    expect(history.undo(), isNull);
  });

  test('답이 바뀌는 칸이 없는 칠하기는 남기지 않고 다시 할 걸음도 그대로 둔다', () {
    paint({a: yes});
    apply(history.undo());
    paint({a: blank, b: blank});

    expect(history.undo(), isNull);
    expect(history.redo(), {a: yes});
  });

  test('한 걸음에는 답이 바뀐 칸만 담는다', () {
    paint({a: yes});
    paint({a: yes, b: no});

    expect(history.undo(), {b: blank}, reason: '이미 가능이던 칸은 되돌리지 않는다');
    expect(history.undo(), {a: blank});
  });

  test('빈 기록에서 되돌리기와 다시 하기는 null이다', () {
    expect(history.undo(), isNull);
    expect(history.redo(), isNull);
  });

  test('걸음이 ${MeetingPaintHistory.limit}개를 넘으면 가장 오래된 걸음부터 버린다', () {
    // 처음 걸음은 답하지 않은 칸을 가능으로, 그 뒤로는 불가능·가능을 번갈아 칠한다
    for (var i = 0; i <= MeetingPaintHistory.limit; i++) {
      paint({a: i.isEven ? yes : no});
    }
    for (var i = 0; i < MeetingPaintHistory.limit; i++) {
      apply(history.undo());
    }

    expect(history.undo(), isNull);
    expect(shown[a], yes, reason: '처음 걸음(답하지 않음 → 가능)은 버렸다');
  });

  test('모두 버리면 되돌릴 것도 다시 할 것도 없다', () {
    paint({a: yes});
    paint({b: yes});
    apply(history.undo());

    history.clear();

    expect(history.undo(), isNull);
    expect(history.redo(), isNull);
  });
}
