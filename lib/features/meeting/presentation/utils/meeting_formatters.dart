import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/shared/api/rest/export.dart';

const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

/// 방식 이름
String meetingModeLabel(MeetingMode mode) => switch (mode) {
  MeetingMode.hourly => '시간별',
  MeetingMode.daily => '날짜별',
  MeetingMode.weekly => '요일별',
};

/// 정각 시각. 24는 하루의 끝으로 '24:00'이다
String hourLabel(int hour) => '$hour:00';

/// '3월 1일 (월)'
String meetingDayLabel(DateTime day) =>
    '${day.month}월 ${day.day}일 (${_weekdayNames[weekdayNumber(day)]})';

/// 미팅 기간. 하루면 그날만, 기간 안의 요일을 일부만 받으면 그 요일을 덧붙인다
String meetingPeriodText(MeetingRead meeting) {
  final first = calendarDay(meeting.startDate);
  final last = calendarDay(meeting.endDate);
  if (first == last) return meetingDayLabel(first);
  final period = '${meetingDayLabel(first)} ~ ${meetingDayLabel(last)}';
  final inPeriod = MeetingDates.period(
    first,
    last.difference(first).inDays + 1,
  ).weekdays;
  final taken = inPeriod.where(meeting.availableDays.contains).toList();
  if (taken.length == inPeriod.length) return period;
  return '$period 중 ${taken.map((d) => _weekdayNames[d]).join('·')}';
}

/// 시간별 미팅의 하루 범위. '6:00 ~ 18:00', 끝이 00:00이면 '24:00'
String meetingHoursText(MeetingRead meeting) {
  final start = _hourOf(meeting.startTime);
  final end = _hourOf(meeting.endTime);
  return '${hourLabel(start)} ~ ${hourLabel(end == 0 ? 24 : end)}';
}

/// 시간 기준 한 줄. 서울은 '한국 시간 기준', 그 밖은 '도시 (UTC±hh:mm) 기준'
String timezoneBasisText(String timezone) => timezone == 'Asia/Seoul'
    ? '한국 시간 기준'
    : '${getTimezoneDisplayName(timezone)} 기준';

int _hourOf(String clock) => int.tryParse(clock.split(':').first) ?? 0;
