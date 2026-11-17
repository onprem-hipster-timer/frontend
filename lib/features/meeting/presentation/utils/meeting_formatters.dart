import 'package:momeet/core/providers/timezone_provider.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/features/meeting/domain/meeting_runs.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// 달의 영문 이름 ('March')
String meetingMonthName(DateTime day) => _monthNames[day.month - 1];

/// 방식 이름
String meetingModeLabel(MeetingMode mode) => switch (mode) {
  MeetingMode.hourly => '시간별',
  MeetingMode.weekly => '요일별',
  MeetingMode.daily || MeetingMode.$unknown => '날짜별',
};

/// 정각 시각. 24는 하루의 끝으로 '24:00'이다
String hourLabel(int hour) => '$hour:00';

/// 0시부터 [minutes]분 뒤의 벽시계 시각. '9:00', '9:30', 다음 날 0시는 '24:00'
String minuteLabel(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

/// backend 요일 번호(0=월요일)의 이름. '월'
String weekdayName(int number) => _weekdayNames[number];

/// '3월 1일 (월)'
String meetingDayLabel(DateTime day) =>
    '${day.month}월 ${day.day}일 (${_weekdayNames[weekdayNumber(day)]})';

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

/// 제목을 비웠을 때 쓰는 제목. 이름이 있으면 'OO님의 모임 일정'
String meetingTitlePlaceholder(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty
      ? '${Terms.meeting} 일정'
      : '$trimmed님의 ${Terms.meeting} 일정';
}

int _hourOf(String clock) => int.tryParse(clock.split(':').first) ?? 0;

/// 격자 칸을 부르는 말(스크린 리더). 시간별 '3월 1일 (월) 9:00 ~ 9:30', 날짜별 '3월 1일 (월)', 요일별 '월요일'
String meetingCellLabel(
  MeetingGrid grid,
  MeetingCell cell,
) => switch (grid.mode) {
  MeetingMode.hourly =>
    '${meetingDayLabel(cell.day)} ${_rangeLabel(cell.startMinute, cell.endMinute)}',
  MeetingMode.weekly => '${weekdayName(weekdayNumber(cell.day))}요일',
  MeetingMode.daily || MeetingMode.$unknown => meetingDayLabel(cell.day),
};

/// 선택된 일정 카드의 제목과 둘째 줄.
///
/// 시간별은 날짜와 시각 범위, 날짜별은 날짜(이어지면 첫날 ~ 마지막 날)와 '하루 종일' 또는 날 수,
/// 요일별은 요일(이어지면 첫 요일 ~ 마지막 요일)과 '하루 종일' 또는 날 수다.
({String title, String detail}) meetingRunText(
  MeetingGrid grid,
  MeetingRun run,
) {
  final first = run.first;
  final last = run.last;
  final days = run.cells.length;
  final hours = first.startMinute == 0 && last.endMinute == minutesPerDay
      ? '하루 종일'
      : _rangeLabel(first.startMinute, last.endMinute);
  return switch (grid.mode) {
    MeetingMode.hourly => (
      title: meetingDayLabel(first.day),
      detail: _rangeLabel(first.startMinute, last.endMinute),
    ),
    MeetingMode.weekly when days == 1 => (
      title: '${weekdayName(first.column)}요일',
      detail: hours,
    ),
    MeetingMode.weekly => (
      title: '${weekdayName(first.column)}요일 ~ ${weekdayName(last.column)}요일',
      detail: '$days일',
    ),
    MeetingMode.daily || MeetingMode.$unknown when days == 1 => (
      title: meetingDayLabel(first.day),
      detail: hours,
    ),
    MeetingMode.daily || MeetingMode.$unknown => (
      title: last.day.month == first.day.month
          ? '${first.day.month}월 ${first.day.day}일 ~ ${last.day.day}일'
          : '${first.day.month}월 ${first.day.day}일 ~ '
                '${last.day.month}월 ${last.day.day}일',
      detail: '$days일',
    ),
  };
}

String _rangeLabel(int start, int end) =>
    '${minuteLabel(start)} ~ ${minuteLabel(end)}';
