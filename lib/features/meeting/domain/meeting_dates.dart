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

/// 모임 후보 날짜.
///
/// backend 미팅은 날짜를 기간(start_date~end_date)과 요일(available_days)로만 담는다. 그래서 고른 날짜는
/// 늘 "첫날부터 마지막 날까지 중 고른 요일에 드는 날 전부"라는 모양을 지킨다. 기간 밖의 날을 더하면 그 사이의
/// 같은 요일 날이 함께 들어오고, 기간 가운데의 날을 빼면 기간 안의 같은 요일 날이 함께 빠진다.
/// 7일 안에서는 요일마다 날이 하나뿐이라 고른 날만 들고 난다.
@immutable
class MeetingDates {
  const MeetingDates._(this.days);

  /// 고른 날짜가 없다
  static const none = MeetingDates._([]);

  /// [days]를 담는 가장 작은 모양
  factory MeetingDates.of(Iterable<DateTime> days) =>
      MeetingDates._(_shape(days.map(calendarDay)));

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

  /// 고른 날의 backend 요일 번호, 오름차순
  List<int> get weekdays =>
      {for (final day in days) weekdayNumber(day)}.toList()..sort();

  bool contains(DateTime day) => days.contains(calendarDay(day));

  /// [day]를 고르거나 뺀다. 모양을 지키려고 같은 요일의 날이 함께 들고 날 수 있다
  MeetingDates toggle(DateTime day) {
    final target = calendarDay(day);
    if (!contains(target)) return MeetingDates.of([...days, target]);
    final rest = [
      for (final d in days)
        if (d != target) d,
    ];
    final shaped = MeetingDates.of(rest);
    if (shaped.days.length == rest.length) return shaped;
    final weekday = weekdayNumber(target);
    return MeetingDates.of([
      for (final d in days)
        if (weekdayNumber(d) != weekday) d,
    ]);
  }

  /// [day]를 더해도 기간이 상한([meetingMaxPeriodMonths])을 넘지 않는지
  bool canAdd(DateTime day) {
    if (isEmpty) return true;
    final target = calendarDay(day);
    final start = target.isBefore(first) ? target : first;
    final end = target.isAfter(last) ? target : last;
    return !end.isAfter(addMonthsClamped(start, meetingMaxPeriodMonths));
  }

  static List<DateTime> _shape(Iterable<DateTime> days) {
    final sorted = {...days}.toList()..sort();
    if (sorted.isEmpty) return const [];
    final weekdays = {for (final day in sorted) weekdayNumber(day)};
    final span = sorted.last.difference(sorted.first).inDays + 1;
    return [
      for (var i = 0; i < span; i++)
        if (weekdays.contains(
          weekdayNumber(sorted.first.add(Duration(days: i))),
        ))
          sorted.first.add(Duration(days: i)),
    ];
  }
}
