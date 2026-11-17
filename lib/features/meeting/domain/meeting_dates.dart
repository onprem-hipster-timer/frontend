import 'package:flutter/foundation.dart';

/// 날짜만 담는 값(그날의 UTC 자정). 일 단위 계산이 일광 절약 시간에 흔들리지 않게 한다
DateTime calendarDay(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

/// backend의 요일 번호 (0=월요일 … 6=일요일)
int weekdayNumber(DateTime day) => day.weekday - 1;

/// [day]에서 [months]달 뒤의 같은 날. 그 달에 같은 날이 없으면 말일이다(backend의 기간 상한과 같은 셈)
DateTime addMonthsClamped(DateTime day, int months) {
  final month = DateTime.utc(day.year, day.month + months);
  final lastDay = DateTime.utc(month.year, month.month + 1, 0).day;
  return DateTime.utc(
    month.year,
    month.month,
    day.day < lastDay ? day.day : lastDay,
  );
}

/// 미팅 기간의 상한(달). 첫날에서 이만큼 뒤의 같은 날까지 고를 수 있다
const meetingMaxPeriodMonths = 3;

/// 모임 날짜: 첫날~마지막 날 기간에서 뺀 날([excluded])을 뺀 날들이다. 첫날과 마지막 날은 빼지 않는다.
///
/// backend 미팅도 같은 모양(start_date·end_date·excluded_dates)으로 담는다.
///
/// 테스트: test/features/meeting/domain/meeting_dates_test.dart
@immutable
class MeetingDates {
  const MeetingDates._(this.days);

  /// 고른 날짜가 없다
  static const none = MeetingDates._([]);

  /// [days]를 날짜로 맞춰 담는다. 첫날~마지막 날 사이에 없는 날은 뺀 날이다
  factory MeetingDates.of(Iterable<DateTime> days) =>
      MeetingDates._({...days.map(calendarDay)}.toList()..sort());

  /// [start]와 [end] 사이(앞뒤 순서는 상관없다)의 날에서 [excluded]를 뺀다. 첫날·마지막 날과 기간 밖의
  /// [excluded]는 버린다
  factory MeetingDates.range(
    DateTime start,
    DateTime end, {
    Iterable<DateTime> excluded = const [],
  }) {
    final a = calendarDay(start);
    final b = calendarDay(end);
    final first = a.isAfter(b) ? b : a;
    final length = (a.difference(b).inDays).abs() + 1;
    final out = excluded.map(calendarDay).toSet();
    return MeetingDates._([
      for (var i = 0; i < length; i++)
        if (i == 0 ||
            i == length - 1 ||
            !out.contains(first.add(Duration(days: i))))
          first.add(Duration(days: i)),
    ]);
  }

  /// [start]부터 이어지는 [length]일
  factory MeetingDates.period(DateTime start, int length) => MeetingDates.range(
    start,
    calendarDay(start).add(Duration(days: length - 1)),
  );

  /// 오름차순 날짜(UTC 자정)
  final List<DateTime> days;

  bool get isEmpty => days.isEmpty;

  DateTime get first => days.first;

  DateTime get last => days.last;

  /// 첫날부터 마지막 날까지의 날 수(뺀 날 포함). 고른 날이 없으면 0
  int get span => isEmpty ? 0 : last.difference(first).inDays + 1;

  /// 첫날부터 마지막 날까지 중 뺀 날, 오름차순
  List<DateTime> get excluded {
    final picked = days.toSet();
    return [
      for (var i = 1; i < span - 1; i++)
        if (!picked.contains(first.add(Duration(days: i))))
          first.add(Duration(days: i)),
    ];
  }

  /// 이어진 7일이고 뺀 날이 없다(요일별의 기간)
  bool get isWeek => span == 7 && days.length == 7;

  bool contains(DateTime day) => days.contains(calendarDay(day));

  /// [day]가 첫날~마지막 날 기간 안인지(뺀 날 포함)
  bool inPeriod(DateTime day) {
    final target = calendarDay(day);
    return !isEmpty && !target.isBefore(first) && !target.isAfter(last);
  }

  /// [day]를 뺄 수 있는지: 기간 안이고 첫날·마지막 날이 아니다
  bool canExclude(DateTime day) {
    final target = calendarDay(day);
    return inPeriod(target) && target != first && target != last;
  }

  /// [day]를 빼거나 되돌린다. 뺄 수 없는 날이면 그대로다
  MeetingDates toggleExcluded(DateTime day) {
    final target = calendarDay(day);
    if (!canExclude(target)) return this;
    final out = excluded.toSet();
    if (!out.remove(target)) out.add(target);
    return MeetingDates.range(first, last, excluded: out);
  }

  /// 뺄 수 있는 토·일요일(첫날·마지막 날이 아닌 기간 안의 주말), 오름차순
  List<DateTime> get weekendsInside => [
    for (var i = 1; i < span - 1; i++)
      if (first.add(Duration(days: i)).weekday >= DateTime.saturday)
        first.add(Duration(days: i)),
  ];

  /// 뺄 수 있는 주말을 모두 뺀다
  MeetingDates withoutWeekends() => MeetingDates.range(
    first,
    last,
    excluded: [...excluded, ...weekendsInside],
  );

  /// 뺀 날을 모두 되돌린다
  MeetingDates withoutExclusions() =>
      isEmpty ? this : MeetingDates.range(first, last);

  /// 기간이 상한([meetingMaxPeriodMonths]) 안인지
  bool get withinMaxPeriod =>
      isEmpty || !last.isAfter(addMonthsClamped(first, meetingMaxPeriodMonths));
}
