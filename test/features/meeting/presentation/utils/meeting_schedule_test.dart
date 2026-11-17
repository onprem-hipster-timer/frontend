import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_schedule.dart';

/// 기기 시간대의 2027년 3월 [day]일 [hour]시
DateTime local(int day, [int hour = 0, int minute = 0]) =>
    DateTime(2027, 3, day, hour, minute);

void main() {
  test('기기 시각으로 하루 중간이면 받은 시각 그대로 연다', () {
    final range = scheduleRangeOf(TimeSpan(local(1, 9), local(1, 12, 30)));

    expect(range.start, local(1, 9));
    expect(range.end, local(1, 12, 30));
    expect(range.start.isUtc, isFalse);
  });

  test('기기 시각으로 0시부터 0시까지인 날들이면 마지막 날 23:59에 끝낸다', () {
    final one = scheduleRangeOf(TimeSpan(local(1), local(2)));
    final three = scheduleRangeOf(TimeSpan(local(1), local(4)));

    expect(one, (start: local(1), end: local(1, 23, 59)));
    expect(three, (start: local(1), end: local(3, 23, 59)));
  });

  test('한쪽만 0시면 그대로 연다', () {
    final range = scheduleRangeOf(TimeSpan(local(1), local(1, 12)));

    expect(range, (start: local(1), end: local(1, 12)));
  });
}
