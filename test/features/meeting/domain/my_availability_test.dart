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

void main() {
  test('저장된 구간이 칸을 모두 덮어야 내 칸이다', () {
    final mine = MyAvailability(
      saved: [
        span(at(9), at(9, 15)),
        span(at(9, 15), at(10)),
        span(at(11), at(11, 15)),
      ],
    );

    expect(mine.has(cell(9)), isTrue, reason: '맞닿은 두 구간이 덮는다');
    expect(mine.has(cell(9, 30)), isTrue);
    expect(mine.has(cell(11)), isFalse, reason: '칸의 일부만 덮는다');
    expect(mine.has(cell(12)), isFalse);
  });

  test('칠한 칸은 내 칸이 되고 맞닿은 칸은 한 구간으로 저장한다', () {
    final mine = MyAvailability().paint([
      cell(9),
      cell(9, 30),
      cell(11),
    ], available: true);

    expect(mine.has(cell(9, 30)), isTrue);
    expect(mine.slots, [span(at(9), at(10)), span(at(11), at(11, 30))]);
  });

  test('지운 칸은 저장된 구간에서 빠지고 건드리지 않은 시각은 그대로 남는다', () {
    final mine = MyAvailability(
      saved: [span(at(9), at(12))],
    ).paint([cell(10)], available: false);

    expect(mine.has(cell(10)), isFalse);
    expect(mine.slots, [span(at(9), at(10)), span(at(10, 30), at(12))]);
  });

  test('격자 밖의 저장된 시각과 칸의 일부만 덮는 시각은 그 칸을 건드리기 전에는 남는다', () {
    final outside = span(at(20), at(22));
    final partial = span(at(13), at(13, 10));
    final mine = MyAvailability(
      saved: [outside, partial],
    ).paint([cell(9)], available: true);

    expect(mine.slots, [cell(9), partial, outside]);
  });

  test('일부만 덮인 칸을 지우면 그 칸 안의 시각이 모두 빠진다', () {
    final mine = MyAvailability(
      saved: [span(at(13), at(13, 10))],
    ).paint([cell(13)], available: false);

    expect(mine.slots, isEmpty);
  });

  test('칠한 칸을 모두 지우면 빈 목록을 저장한다', () {
    final cells = [cell(9), cell(9, 30), cell(10)];
    final mine = MyAvailability(
      saved: [span(at(9), at(10, 30))],
    ).paint(cells, available: true).paint(cells, available: false);

    expect(mine.slots, isEmpty);
    expect(cells.where(mine.has), isEmpty);
  });

  test('같은 칸을 여러 번 칠하고 지우면 마지막 것을 따른다', () {
    final mine = MyAvailability()
        .paint([cell(9)], available: true)
        .paint([cell(9)], available: false)
        .paint([cell(9)], available: true);

    expect(mine.slots, [cell(9)]);
  });

  test('저장된 구간을 새로 받아도 칠하고 지운 칸은 그대로 덮는다', () {
    final mine = MyAvailability()
        .paint([cell(9)], available: true)
        .paint([cell(10)], available: false)
        .withSaved([span(at(10), at(11))]);

    expect(mine.has(cell(9)), isTrue);
    expect(mine.has(cell(10)), isFalse);
    expect(mine.has(cell(10, 30)), isTrue);
    expect(mine.slots, [cell(9), cell(10, 30)]);
  });

  test('저장한 값을 다시 받아 덮어도 저장할 값은 같다', () {
    final painted =
        MyAvailability(saved: [span(at(8), at(9)), span(at(20), at(21))])
            .paint([cell(8, 30), cell(9)], available: true)
            .paint([cell(8)], available: false);

    expect(painted.withSaved(painted.slots).slots, painted.slots);
  });
}
