import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/domain/time_span.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/timezone.dart' as tz;

/// 하루의 분
const minutesPerDay = 24 * 60;

/// 격자의 칸 하나. 화면 자리([column], [row])와 그 칸이 뜻하는 실제 시각 구간([span])을 함께 갖는다
@immutable
class MeetingCell {
  const MeetingCell({
    required this.index,
    required this.column,
    required this.row,
    required this.day,
    required this.startMinute,
    required this.endMinute,
    required this.span,
    required this.joinsPrevious,
  });

  /// [MeetingGrid.cells]에서의 자리(화면 순서)
  final int index;
  final int column;
  final int row;

  /// 미팅 시간대의 날짜(그날의 UTC 자정 값)
  final DateTime day;

  /// [day] 0시부터 센 벽시계 분. 끝이 다음 날 0시면 [minutesPerDay]
  final int startMinute;
  final int endMinute;

  /// 칸이 뜻하는 UTC 구간
  final TimeSpan span;

  /// 화면 순서로 바로 앞 칸과 이어지는지. 이어지는 칸끼리만 한 일정 후보로 묶는다
  final bool joinsPrevious;
}

/// 미팅 하나의 격자. 방식([MeetingMode])마다 모양이 다르다.
///
/// - 시간별: 날짜가 열, 하루 범위를 슬롯 분으로 나눈 벽시계 시각이 줄
/// - 날짜별: 일요일부터 한 주가 한 줄인 달력, 하루가 한 칸
/// - 요일별: 월요일부터 일곱 요일이 한 줄
///
/// 칸은 언제나 미팅 시간대의 실제 시각 구간이다. 날짜별·요일별 칸도 하루 범위 전체의 구간이라
/// 다른 방식으로 바꿔 읽어도 같은 가능 시간이 그대로 맞는다.
///
/// 테스트: test/features/meeting/domain/meeting_grid_test.dart
class MeetingGrid {
  MeetingGrid._({
    required this.mode,
    required this.columns,
    required this.rows,
    required this.cells,
    required this.columnDays,
    required this.rowMinutes,
    required tz.Location location,
  }) : _location = location,
       _table = List.filled(columns * rows, null) {
    for (final cell in cells) {
      _table[cell.row * columns + cell.column] = cell;
    }
  }

  /// [meeting]의 격자. 미팅 시간대가 시간대 DB에 있어야 한다
  factory MeetingGrid.of(MeetingRead meeting) {
    final location = tz.getLocation(meeting.timezone);
    final dayStart = clockMinutes(meeting.startTime);
    final endClock = clockMinutes(meeting.endTime);
    final dayEnd = endClock == 0 ? minutesPerDay : endClock;
    final days = meetingDays(meeting);
    return switch (inferMeetingMode(meeting)) {
      MeetingMode.hourly => _hourly(
        location,
        days,
        dayStart,
        dayEnd,
        meeting.timeSlotMinutes,
      ),
      MeetingMode.weekly => _weekly(location, days, dayStart, dayEnd),
      MeetingMode.daily ||
      MeetingMode.$unknown => _daily(location, days, dayStart, dayEnd),
    };
  }

  final MeetingMode mode;
  final int columns;
  final int rows;

  /// 화면 순서의 칸. 날짜와 시각이 빠른 칸이 앞이다(요일별은 월요일부터)
  final List<MeetingCell> cells;

  /// 시간별의 열마다 날짜. 다른 방식은 비어 있다
  final List<DateTime> columnDays;

  /// 시간별의 줄마다 시작 벽시계 분. 다른 방식은 비어 있다
  final List<int> rowMinutes;

  final tz.Location _location;
  final List<MeetingCell?> _table;

  /// ([column], [row]) 자리의 칸. 그 자리에 칸이 없으면(기간 밖의 날, 일광 절약 시간으로 없는 시각) null
  MeetingCell? at(int column, int row) {
    if (column < 0 || column >= columns || row < 0 || row >= rows) return null;
    return _table[row * columns + column];
  }

  /// 두 자리를 꼭짓점으로 하는 사각형 안의 칸, 화면 순서
  List<MeetingCell> within((int, int) from, (int, int) to) {
    final (c0, r0) = from;
    final (c1, r1) = to;
    final left = c0 < c1 ? c0 : c1;
    final right = c0 < c1 ? c1 : c0;
    final top = r0 < r1 ? r0 : r1;
    final bottom = r0 < r1 ? r1 : r0;
    return [
      for (final cell in cells)
        if (cell.column >= left &&
            cell.column <= right &&
            cell.row >= top &&
            cell.row <= bottom)
          cell,
    ];
  }

  /// 이어지는 칸들([cells]의 일부)이 뜻하는 실제 구간. 요일별은 첫 칸의 날부터 칸 수만큼의 날로 잡는다
  TimeSpan spanOf(List<MeetingCell> cells) {
    final first = cells.first;
    final last = cells.last;
    if (mode != MeetingMode.weekly) {
      return TimeSpan(first.span.start, last.span.end);
    }
    final lastDay = first.day.add(Duration(days: cells.length - 1));
    return TimeSpan(
      first.span.start,
      _instant(_location, lastDay, last.endMinute),
    );
  }

  static MeetingGrid _hourly(
    tz.Location location,
    List<DateTime> days,
    int dayStart,
    int dayEnd,
    int slotMinutes,
  ) {
    final rowMinutes = [
      for (var minute = dayStart; minute < dayEnd; minute += slotMinutes)
        minute,
    ];
    final cells = <MeetingCell>[];
    for (var column = 0; column < days.length; column++) {
      final day = days[column];
      for (var row = 0; row < rowMinutes.length; row++) {
        final start = rowMinutes[row];
        final end = row + 1 < rowMinutes.length ? rowMinutes[row + 1] : dayEnd;
        final span = TimeSpan(
          _instant(location, day, start),
          _instant(location, day, end),
        );
        // 일광 절약 시간이 시작하는 날, 없는 벽시계 시각만으로 된 칸은 두지 않는다
        if (span.isEmpty) continue;
        final previous = cells.isEmpty ? null : cells.last;
        cells.add(
          MeetingCell(
            index: cells.length,
            column: column,
            row: row,
            day: day,
            startMinute: start,
            endMinute: end,
            span: span,
            joinsPrevious:
                previous != null &&
                previous.column == column &&
                previous.span.end == span.start,
          ),
        );
      }
    }
    return MeetingGrid._(
      mode: MeetingMode.hourly,
      columns: days.length,
      rows: rowMinutes.length,
      cells: cells,
      columnDays: days,
      rowMinutes: rowMinutes,
      location: location,
    );
  }

  static MeetingGrid _daily(
    tz.Location location,
    List<DateTime> days,
    int dayStart,
    int dayEnd,
  ) {
    if (days.isEmpty) return _empty(MeetingMode.daily, location);
    final firstSunday = days.first.subtract(
      Duration(days: days.first.weekday % 7),
    );
    final cells = <MeetingCell>[];
    for (final day in days) {
      final span = TimeSpan(
        _instant(location, day, dayStart),
        _instant(location, day, dayEnd),
      );
      final previous = cells.isEmpty ? null : cells.last;
      cells.add(
        MeetingCell(
          index: cells.length,
          column: day.weekday % 7,
          row: day.difference(firstSunday).inDays ~/ 7,
          day: day,
          startMinute: dayStart,
          endMinute: dayEnd,
          span: span,
          joinsPrevious: previous != null && previous.span.end == span.start,
        ),
      );
    }
    return MeetingGrid._(
      mode: MeetingMode.daily,
      columns: 7,
      rows: cells.last.row + 1,
      cells: cells,
      columnDays: const [],
      rowMinutes: const [],
      location: location,
    );
  }

  static MeetingGrid _weekly(
    tz.Location location,
    List<DateTime> days,
    int dayStart,
    int dayEnd,
  ) {
    final ordered = [...days]
      ..sort((a, b) => weekdayNumber(a).compareTo(weekdayNumber(b)));
    final cells = <MeetingCell>[];
    for (final day in ordered) {
      final column = weekdayNumber(day);
      final previous = cells.isEmpty ? null : cells.last;
      cells.add(
        MeetingCell(
          index: cells.length,
          column: column,
          row: 0,
          day: day,
          startMinute: dayStart,
          endMinute: dayEnd,
          span: TimeSpan(
            _instant(location, day, dayStart),
            _instant(location, day, dayEnd),
          ),
          joinsPrevious: previous != null && previous.column == column - 1,
        ),
      );
    }
    return MeetingGrid._(
      mode: MeetingMode.weekly,
      columns: 7,
      rows: 1,
      cells: cells,
      columnDays: const [],
      rowMinutes: const [],
      location: location,
    );
  }

  static MeetingGrid _empty(MeetingMode mode, tz.Location location) =>
      MeetingGrid._(
        mode: mode,
        columns: 0,
        rows: 0,
        cells: const [],
        columnDays: const [],
        rowMinutes: const [],
        location: location,
      );
}

/// 미팅 날짜: 기간에서 제외 날짜를 뺀 날(그날의 UTC 자정 값), 빠른 순
List<DateTime> meetingDays(MeetingRead meeting) {
  final first = calendarDay(meeting.startDate);
  final last = calendarDay(meeting.endDate);
  final excluded = {for (final day in meeting.excludedDates) calendarDay(day)};
  return [
    for (
      var day = first;
      !day.isAfter(last);
      day = day.add(const Duration(days: 1))
    )
      if (!excluded.contains(day)) day,
  ];
}

/// `HH:MM[:SS]` 시각의 0시부터 분
int clockMinutes(String clock) {
  final parts = clock.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// 다른 참여자 [count]명이 되는 칸의 농도 단계(0~5). [total]은 다른 참여자 수다.
///
/// 0은 아무도 안 되는 칸, 5는 모두 되는 칸이고, 그 사이는 비율을 네 단계로 올려 나눈다.
/// 다른 참여자가 넷 이하면 한 명이 늘 때마다 한 단계씩 진해진다.
int availabilityShade(int count, int total) {
  if (count <= 0 || total <= 0) return 0;
  if (count >= total) return 5;
  return (count * 4 + total - 1) ~/ total;
}

/// [location]의 [day] 0시에서 벽시계 [minute]분 뒤의 UTC 시각. 없는 시각은 전환 뒤로 민다
DateTime _instant(tz.Location location, DateTime day, int minute) =>
    tz.TZDateTime(location, day.year, day.month, day.day, 0, minute).toUtc();
