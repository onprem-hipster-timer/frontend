import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momeet/shared/api/rest/export.dart';

// ============================================================
// 날짜 유틸리티
// ============================================================

final _dateFormatFull = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
final _dateFormatShort = DateFormat('yyyy년 MM월 dd일', 'ko');
final _timeFormat = DateFormat('HH:mm', 'ko');
final _dateTimeFormat = DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko');

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

bool isAllDay(DateTime start, DateTime end) {
  return start.hour == 0 &&
      start.minute == 0 &&
      end.hour == 0 &&
      end.minute == 0 &&
      end.difference(start).inHours >= 24;
}

/// [compareDate]가 일정 기간 [startDate, endDate]에 포함되는지 검사합니다.
///
/// 시작일·종료일과 같은 날이거나, 두 날짜 사이에 걸친 멀티-데이 일정을
/// 캘린더 셀에서 올바르게 판별하기 위해 사용합니다.
bool isIncludeDay(DateTime startDate, DateTime endDate, DateTime compareDate) {
  // 종일/자정 종료 일정은 종료 시각(자정)을 exclusive end로 다루므로,
  // 비교 전에 effective end를 하루 당겨 다음 날 셀에 포함되지 않도록 한다.
  final effectiveEnd = isAllDay(startDate, endDate)
      ? endDate.subtract(const Duration(days: 1))
      : endDate;
  return isSameDay(startDate, compareDate) ||
      isSameDay(effectiveEnd, compareDate) ||
      (startDate.isBefore(compareDate) && effectiveEnd.isAfter(compareDate));
}

String formatScheduleTime(ScheduleRead schedule) {
  final start = schedule.startTime.toLocal();
  final end = schedule.endTime.toLocal();

  if (isAllDay(start, end)) {
    if (isSameDay(start, end.subtract(const Duration(days: 1)))) {
      return '${_dateFormatFull.format(start)} 종일';
    } else {
      return '${_dateFormatShort.format(start)} ~ '
          '${_dateFormatShort.format(end.subtract(const Duration(days: 1)))}';
    }
  }

  if (isSameDay(start, end)) {
    return '${_dateFormatFull.format(start)}\n'
        '${_timeFormat.format(start)} ~ ${_timeFormat.format(end)}';
  } else {
    return '${_dateTimeFormat.format(start)} ~\n'
        '${_dateTimeFormat.format(end)}';
  }
}

// ============================================================
// ScheduleState 매핑
// ============================================================

String getScheduleStatusText(ScheduleState state) => switch (state) {
  ScheduleState.planned => '계획됨',
  ScheduleState.confirmed => '확정됨',
  ScheduleState.cancelled => '취소됨',
  ScheduleState.$unknown => '알 수 없음',
};

Color getScheduleStatusColor(ScheduleState state) => switch (state) {
  ScheduleState.planned => Colors.orange,
  ScheduleState.confirmed => Colors.green,
  ScheduleState.cancelled => Colors.red,
  ScheduleState.$unknown => Colors.grey,
};

// ============================================================
// TimerStatus 매핑
// ============================================================

IconData getTimerStatusIcon(TimerStatus status) => switch (status) {
  TimerStatus.notStarted => Icons.hourglass_empty,
  TimerStatus.running => Icons.play_arrow,
  TimerStatus.paused => Icons.pause,
  TimerStatus.completed => Icons.check_circle,
  TimerStatus.cancelled => Icons.cancel,
  TimerStatus.$unknown => Icons.timer,
};

Color getTimerStatusColor(TimerStatus status) => switch (status) {
  TimerStatus.notStarted => Colors.blueGrey,
  TimerStatus.running => Colors.green,
  TimerStatus.paused => Colors.orange,
  TimerStatus.completed => Colors.blue,
  TimerStatus.cancelled => Colors.grey,
  TimerStatus.$unknown => Colors.grey,
};

String getTimerStatusText(TimerStatus status) => switch (status) {
  TimerStatus.notStarted => '시작 전',
  TimerStatus.running => '진행중',
  TimerStatus.paused => '일시정지',
  TimerStatus.completed => '완료',
  TimerStatus.cancelled => '취소',
  TimerStatus.$unknown => '알 수 없음',
};

// ============================================================
// RFC 5545 RRULE 파서
// ============================================================

/// "FREQ=WEEKLY;BYDAY=MO,WE" → "매주 (월, 수)"
String parseRecurrenceRule(String rule) {
  final upper = rule.toUpperCase();

  final freqMatch = RegExp(r'FREQ=(\w+)').firstMatch(upper);
  if (freqMatch == null) return rule;

  final freq = freqMatch.group(1);
  final interval = RegExp(r'INTERVAL=(\d+)').firstMatch(upper)?.group(1) ?? '1';
  final intervalNum = int.tryParse(interval) ?? 1;

  final byDay = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(upper)?.group(1);

  switch (freq) {
    case 'DAILY':
      return intervalNum > 1 ? '$intervalNum일마다' : '매일';
    case 'WEEKLY':
      final days = byDay != null ? ' (${_translateDays(byDay)})' : '';
      return intervalNum > 1 ? '$intervalNum주마다$days' : '매주$days';
    case 'MONTHLY':
      return intervalNum > 1 ? '$intervalNum개월마다' : '매월';
    case 'YEARLY':
      return intervalNum > 1 ? '$intervalNum년마다' : '매년';
    default:
      return rule;
  }
}

String _translateDays(String byDay) {
  const dayMap = {
    'MO': '월',
    'TU': '화',
    'WE': '수',
    'TH': '목',
    'FR': '금',
    'SA': '토',
    'SU': '일',
  };
  return byDay.split(',').map((d) => dayMap[d.trim()] ?? d).join(', ');
}
