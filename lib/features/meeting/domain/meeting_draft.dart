import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 달력의 날짜 칸 상태
enum MeetingDayState {
  /// 고를 수 있다
  open,

  /// 골랐다
  selected,

  /// 고를 수 있지만 고르면 시간별에서 날짜별로 바뀐다
  leavesHourly,

  /// 고를 수 없다(지난 날, 기간 상한 밖)
  unavailable,
}

/// 모임 만들기 폼의 값과 값끼리의 규칙. 값이 규칙에 걸리면 묻지 않고 맞춘다.
///
/// 테스트: test/features/meeting/domain/meeting_draft_test.dart
@immutable
class MeetingDraft {
  const MeetingDraft({
    this.mode = MeetingMode.hourly,
    this.dates = MeetingDates.none,
    this.startHour = hourlyEarliestHour,
    this.endHour = 18,
    this.isPublic = true,
    this.allowGuests = true,
  });

  final MeetingMode mode;
  final MeetingDates dates;

  /// 시간별 하루 범위의 시작(시, 6~23)
  final int startHour;

  /// 시간별 하루 범위의 끝(시, 시작+1~24). 24는 하루의 끝이다
  final int endHour;

  /// 링크가 있는 누구나 볼 수 있는지
  final bool isPublic;

  /// 게스트 로그인을 받는지. 공개가 아니면 늘 false다
  final bool allowGuests;

  /// 고른 기간이 시간별에 들어가는지
  bool get hourlyAvailable => dates.span <= hourlyMaxDays;

  /// [day]를 누른다. 요일별은 그날부터 7일을 고르고, 시간별에서 기간이 5일을 넘으면 날짜별로 바꾼다
  MeetingDraft tapDay(DateTime day) {
    if (mode == MeetingMode.weekly) {
      return _copy(dates: MeetingDates.period(day, weeklyDays));
    }
    final next = dates.toggle(day);
    final leaves = mode == MeetingMode.hourly && next.span > hourlyMaxDays;
    return _copy(dates: next, mode: leaves ? MeetingMode.daily : mode);
  }

  /// 방식을 바꾼다. 기간이 5일을 넘으면 시간별로 바꾸지 않고, 요일별은 첫날부터 7일로 맞춘다
  MeetingDraft withMode(MeetingMode next) => switch (next) {
    MeetingMode.hourly when !hourlyAvailable => this,
    MeetingMode.weekly => _copy(
      mode: next,
      dates: dates.isEmpty
          ? dates
          : MeetingDates.period(dates.first, weeklyDays),
    ),
    _ => _copy(mode: next),
  };

  /// 시작 시각을 바꾼다. 끝이 시작보다 늦지 않으면 끝을 한 시간 뒤로 민다
  MeetingDraft withStartHour(int hour) =>
      _copy(startHour: hour, endHour: endHour > hour ? endHour : hour + 1);

  MeetingDraft withEndHour(int hour) => _copy(endHour: hour);

  /// 공개를 끄면 게스트 로그인도 끈다
  MeetingDraft withPublic(bool value) =>
      _copy(isPublic: value, allowGuests: value && allowGuests);

  /// 공개가 아니면 게스트 로그인을 켜지 않는다
  MeetingDraft withGuests(bool value) =>
      isPublic ? _copy(allowGuests: value) : this;

  /// [today] 기준 [day] 칸의 상태
  MeetingDayState dayState(DateTime day, {required DateTime today}) {
    if (dates.contains(day)) return MeetingDayState.selected;
    if (calendarDay(day).isBefore(calendarDay(today))) {
      return MeetingDayState.unavailable;
    }
    if (mode == MeetingMode.weekly) return MeetingDayState.open;
    if (!dates.canAdd(day)) return MeetingDayState.unavailable;
    if (mode == MeetingMode.hourly && dates.toggle(day).span > hourlyMaxDays) {
      return MeetingDayState.leavesHourly;
    }
    return MeetingDayState.open;
  }

  /// 만들기 요청. 기간은 첫날~마지막 날이고 그 사이 고르지 않은 날은 제외 날짜다. 시간을 묻지 않는 방식은 하루
  /// 전체(0시~다음 날 0시)로 보낸다.
  ///
  /// 게스트 로그인([allowGuests])은 담지 않는다. backend는 새 미팅에 게스트를 켜지 않으므로 만든 뒤 공개로
  /// 열고 켠다(`MeetingMutations.create`).
  MeetingCreate toMeetingCreate({
    required String title,
    required String timezone,
  }) {
    final hourly = mode == MeetingMode.hourly;
    return MeetingCreate(
      title: title,
      startDate: dates.first,
      endDate: dates.last,
      excludedDates: dates.excluded,
      timezone: timezone,
      mode: mode,
      startTime: clockOf(hourly ? startHour : 0),
      endTime: clockOf(hourly ? endHour : 0),
    );
  }

  MeetingDraft _copy({
    MeetingMode? mode,
    MeetingDates? dates,
    int? startHour,
    int? endHour,
    bool? isPublic,
    bool? allowGuests,
  }) => MeetingDraft(
    mode: mode ?? this.mode,
    dates: dates ?? this.dates,
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    isPublic: isPublic ?? this.isPublic,
    allowGuests: allowGuests ?? this.allowGuests,
  );
}
