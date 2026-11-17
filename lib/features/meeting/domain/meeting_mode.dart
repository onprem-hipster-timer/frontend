import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 시간별의 기간 상한(일). 넘으면 시간 격자가 화면에 들어가지 않는다
const hourlyMaxDays = 5;

/// 요일별의 기간(일)
const weeklyDays = 7;

/// 시간별 하루 범위가 시작할 수 있는 가장 이른 시각(시). 시간을 묻지 않는 방식은 0시에 시작하므로 이것으로 가른다
const hourlyEarliestHour = 6;

/// [meeting]을 만든 방식. 하루 범위가 0시에 시작하면 시간을 묻지 않은 방식이고, 그중 기간이 7일이면 요일별이다
MeetingMode inferMeetingMode(MeetingRead meeting) {
  if (!isMidnight(meeting.startTime)) return MeetingMode.hourly;
  final days =
      calendarDay(
        meeting.endDate,
      ).difference(calendarDay(meeting.startDate)).inDays +
      1;
  return days == weeklyDays ? MeetingMode.weekly : MeetingMode.daily;
}

/// `HH:MM[:SS]` 시각이 0시 정각인지
bool isMidnight(String clock) =>
    clock.split(':').every((part) => (num.tryParse(part) ?? -1) == 0);

/// [hour]시 정각의 backend 시각 문자열. 24시는 하루의 끝인 00:00이다
String clockOf(int hour) => '${(hour % 24).toString().padLeft(2, '0')}:00:00';
