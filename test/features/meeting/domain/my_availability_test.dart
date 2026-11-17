import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/my_availability.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';

/// 2027년 3월 1일 [hour]시 [minute]분(UTC)
DateTime at(int hour, [int minute = 0]) =>
    DateTime.utc(2027, 3, 1, hour, minute);

/// [hour]시부터 30분 칸
TimeSpan cell(int hour, [int minute = 0]) {
  final start = at(hour, minute);
  return TimeSpan(start, start.add(const Duration(minutes: 30)));
}

TimeSpan span(DateTime from, DateTime to) => TimeSpan(from, to);

const available = MeetingAnswer.available;
const unavailable = MeetingAnswer.unavailable;
const unanswered = MeetingAnswer.unanswered;

extension on MyAvailability {
  MyAvailability set(Iterable<TimeSpan> cells, MeetingAnswer answer) =>
      paint({for (final cell in cells) cell: answer});
}

void main() {
  test('저장된 구간이 칸을 모두 덮어야 그 답이다', () {
    final mine = MyAvailability(
      available: [
        span(at(9), at(9, 15)),
        span(at(9, 15), at(10)),
        span(at(11), at(11, 15)),
      ],
      unavailable: [span(at(12), at(13))],
    );

    expect(mine.answerAt(cell(9)), available, reason: '맞닿은 두 구간이 덮는다');
    expect(mine.answerAt(cell(9, 30)), available);
    expect(mine.answerAt(cell(11)), unanswered, reason: '칸의 일부만 덮는다');
    expect(mine.answerAt(cell(12, 30)), unavailable);
    expect(mine.answerAt(cell(14)), unanswered);
  });

  test('가능으로 칠한 칸은 가능이 되고 맞닿은 칸은 한 구간으로 저장한다', () {
    final mine = MyAvailability().set([
      cell(9),
      cell(9, 30),
      cell(11),
    ], available);

    expect(mine.answerAt(cell(9, 30)), available);
    expect(mine.slots.available, [
      span(at(9), at(10)),
      span(at(11), at(11, 30)),
    ]);
    expect(mine.slots.unavailable, isEmpty);
  });

  test('가능 구간 가운데를 불가능으로 칠하면 가능 구간을 나눠 겹치지 않게 보낸다', () {
    final mine = MyAvailability(
      available: [span(at(9), at(12))],
    ).set([cell(10)], unavailable);

    expect(mine.answerAt(cell(10)), unavailable);
    expect(mine.slots.available, [
      span(at(9), at(10)),
      span(at(10, 30), at(12)),
    ]);
    expect(mine.slots.unavailable, [cell(10)]);
  });

  test('지운 칸은 두 종류 모두에서 빠지고 건드리지 않은 시각은 그대로 남는다', () {
    final mine = MyAvailability(
      available: [span(at(9), at(12))],
      unavailable: [span(at(12), at(14))],
    ).set([cell(10), cell(13)], unanswered);

    expect(mine.answerAt(cell(10)), unanswered);
    expect(mine.answerAt(cell(13)), unanswered);
    expect(mine.slots.available, [
      span(at(9), at(10)),
      span(at(10, 30), at(12)),
    ]);
    expect(mine.slots.unavailable, [
      span(at(12), at(13)),
      span(at(13, 30), at(14)),
    ]);
  });

  test('격자 밖의 저장된 시각과 칸의 일부만 덮는 시각은 그 칸을 건드리기 전에는 남는다', () {
    final outside = span(at(20), at(22));
    final partial = span(at(13), at(13, 10));
    final mine = MyAvailability(
      available: [outside, partial],
      unavailable: [span(at(23), at(23, 30))],
    ).set([cell(9)], available);

    expect(mine.slots.available, [cell(9), partial, outside]);
    expect(mine.slots.unavailable, [span(at(23), at(23, 30))]);
  });

  test('일부만 덮인 칸을 지우면 그 칸 안의 시각이 모두 빠진다', () {
    final mine = MyAvailability(
      available: [span(at(13), at(13, 10))],
      unavailable: [span(at(13, 10), at(13, 20))],
    ).set([cell(13)], unanswered);

    expect(mine.slots.available, isEmpty);
    expect(mine.slots.unavailable, isEmpty);
  });

  test('저장된 두 종류가 겹쳐 있어도 보낼 때는 겹치지 않는다', () {
    final mine = MyAvailability(
      available: [span(at(9), at(11))],
      unavailable: [span(at(10), at(12))],
    );

    expect(mine.slots.available, [span(at(9), at(11))]);
    expect(mine.slots.unavailable, [span(at(11), at(12))]);
  });

  test('같은 칸을 여러 번 칠하고 지우면 마지막 것을 따른다', () {
    final mine = MyAvailability()
        .set([cell(9)], available)
        .set([cell(9)], unavailable)
        .set([cell(9)], unanswered)
        .set([cell(9)], unavailable);

    expect(mine.slots.available, isEmpty);
    expect(mine.slots.unavailable, [cell(9)]);
  });

  test('저장된 구간을 새로 받아도 칠하고 지운 칸은 그대로 덮는다', () {
    final mine = MyAvailability()
        .set([cell(9)], available)
        .set([cell(10)], unanswered)
        .set([cell(11)], unavailable)
        .withSaved(
          available: [span(at(10), at(11))],
          unavailable: [span(at(11), at(12))],
        );

    expect(mine.answerAt(cell(9)), available);
    expect(mine.answerAt(cell(10)), unanswered);
    expect(mine.answerAt(cell(10, 30)), available);
    expect(mine.answerAt(cell(11)), unavailable);
    expect(mine.answerAt(cell(11, 30)), unavailable);
    expect(mine.slots.available, [cell(9), cell(10, 30)]);
    expect(mine.slots.unavailable, [span(at(11), at(12))]);
  });

  test('저장한 값을 다시 받아 덮어도 저장할 값은 같다', () {
    final painted =
        MyAvailability(
          available: [span(at(8), at(9)), span(at(20), at(21))],
          unavailable: [span(at(15), at(16))],
        ).set([cell(8, 30), cell(9)], available).set([cell(8)], unanswered).set(
          [cell(15, 30), cell(16)],
          unavailable,
        );
    final slots = painted.slots;
    final again = painted.withSaved(
      available: slots.available,
      unavailable: slots.unavailable,
    );

    expect(again.slots.available, slots.available);
    expect(again.slots.unavailable, slots.unavailable);
  });
}
