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

/// 모임 후보 날짜: 고른 날 그대로다.
///
/// backend 미팅은 첫날~마지막 날 기간과 그 사이의 제외 날짜([excluded])로 담는다.
@immutable
class MeetingDates {
  const MeetingDates._(this.days);

  /// 고른 날짜가 없다
  static const none = MeetingDates._([]);

  /// [days]를 날짜로 맞춰 겹치지 않게 담는다
  factory MeetingDates.of(Iterable<DateTime> days) =>
      MeetingDates._({...days.map(calendarDay)}.toList()..sort());

  /// [start]부터 이어지는 [length]일
  factory MeetingDates.period(DateTime start, int length) {
    final first = calendarDay(start);
    return MeetingDates._([
      for (var i = 0; i < length; i++) first.add(Duration(days: i)),
    ]);
  }

  /// 오름차순 날짜(UTC 자정)
  final List<DateTime> days;

  bool get isEmpty => days.isEmpty;

  DateTime get first => days.first;

  DateTime get last => days.last;

  /// 첫날부터 마지막 날까지의 날 수(고르지 않은 날 포함). 고른 날이 없으면 0
  int get span => isEmpty ? 0 : last.difference(first).inDays + 1;

  /// 첫날부터 마지막 날까지 중 고르지 않은 날, 오름차순. 첫날과 마지막 날은 늘 고른 날이다
  List<DateTime> get excluded {
    final picked = days.toSet();
    return [
      for (var i = 1; i < span - 1; i++)
        if (!picked.contains(first.add(Duration(days: i))))
          first.add(Duration(days: i)),
    ];
  }

  bool contains(DateTime day) => days.contains(calendarDay(day));

  /// [day]를 고르거나 뺀다
  MeetingDates toggle(DateTime day) {
    final target = calendarDay(day);
    return MeetingDates.of(
      contains(target)
          ? [
              for (final d in days)
                if (d != target) d,
            ]
          : [...days, target],
    );
  }

  /// [day]를 더해도 기간이 상한([meetingMaxPeriodMonths])을 넘지 않는지
  bool canAdd(DateTime day) => MeetingDates.of([...days, day]).withinMaxPeriod;

  /// 기간이 상한([meetingMaxPeriodMonths]) 안인지
  bool get withinMaxPeriod =>
      isEmpty || !last.isAfter(addMonthsClamped(first, meetingMaxPeriodMonths));
}
