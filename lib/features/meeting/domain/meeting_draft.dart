import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 시간별 하루 범위의 처음 값(시)
const meetingDefaultStartHour = 6;

/// 시간별 하루 범위의 처음 값의 끝(시)
const meetingDefaultEndHour = 18;

/// 모임 만들기 폼의 값과 값끼리의 규칙. 값이 규칙에 걸리면 묻지 않고 맞춘다.
///
/// 테스트: test/features/meeting/domain/meeting_draft_test.dart
@immutable
class MeetingDraft {
  const MeetingDraft({
    this.mode = MeetingMode.hourly,
    this.dates = MeetingDates.none,
    this.startHour = meetingDefaultStartHour,
    this.endHour = meetingDefaultEndHour,
    this.isPublic = true,
    this.allowGuests = true,
    this.emails = const [],
    this.domains = const [],
    this.onlyMe = false,
  });

  final MeetingMode mode;
  final MeetingDates dates;

  /// 시간별 하루 범위의 시작(시, 0~23)
  final int startHour;

  /// 시간별 하루 범위의 끝(시, 시작+1~24). 24는 하루의 끝이다
  final int endHour;

  /// 링크가 있는 누구나 볼 수 있는지
  final bool isPublic;

  /// 게스트 로그인을 받는지. 공개가 아니면 늘 false다
  final bool allowGuests;

  /// 비공개 모임을 열 수 있는 이메일(소문자, 겹치지 않음). 공개면 비어 있다
  final List<String> emails;

  /// 비공개 모임을 열 수 있는 이메일의 도메인(소문자, 겹치지 않음). 공개면 비어 있다
  final List<String> domains;

  /// 비공개 모임을 지금은 나만 본다(넣은 이메일과 상관없이 아무도 열 수 없다). 공개면 false다
  final bool onlyMe;

  /// 이 기기에 두었던 폼 값을 폼의 규칙으로 다시 만든다. 폼이 저절로 맞추는 값(시간별 날짜,
  /// 요일별 7일, 비공개의 게스트 로그인, 공개의 이메일·나만 보기, 시작보다 늦은 끝)은 같은 규칙으로 맞추고, 형식이
  /// 아닌 이메일·도메인은 버린다. 폼이 만들 수 없는 값(알 수 없는 방식, 0~24시 밖의 시각, [today]보다 앞의 날,
  /// 3개월을 넘는 기간)이면 null이다
  static MeetingDraft? restore({
    required MeetingMode mode,
    required Iterable<DateTime> days,
    required int startHour,
    required int endHour,
    required bool isPublic,
    required bool allowGuests,
    required DateTime today,
    Iterable<String> access = const [],
    bool onlyMe = false,
  }) {
    final dates = MeetingDates.of(days);
    if (mode == MeetingMode.$unknown ||
        startHour < 0 ||
        startHour > 23 ||
        endHour < 1 ||
        endHour > 24 ||
        !dates.withinMaxPeriod ||
        (!dates.isEmpty && dates.first.isBefore(calendarDay(today)))) {
      return null;
    }
    final draft = MeetingDraft(
      mode: MeetingMode.daily,
      dates: dates,
      endHour: endHour,
      allowGuests: allowGuests,
    ).withStartHour(startHour).withPublic(isPublic).withMode(mode);
    return access
        .map(parseMeetingAccessEntry)
        .nonNulls
        .fold(draft, (draft, entry) => draft.withAccessEntry(entry))
        .withOnlyMe(onlyMe);
  }

  /// 시간별로 받을 수 있는 날짜인지: 모이는 날(뺀 날 제외)이 [hourlyMaxDays]일 이하이고 기간(뺀 날 포함)이
  /// [hourlyMaxSpanDays]일 이하다. 시간별을 고를 수 있는지는 모두 이 규칙을 따른다
  bool get hourlyAvailable =>
      dates.days.length <= hourlyMaxDays && dates.span <= hourlyMaxSpanDays;

  /// 날짜를 바꾼다. 방식은 그대로다(방식과 맞추는 것은 부르는 쪽이 한다)
  MeetingDraft withDates(MeetingDates next) => _copy(dates: next);

  /// 방식을 바꾼다. 시간별을 고를 수 없는 날짜면 시간별로 바꾸지 않고, 요일별은 첫날부터 7일로 맞추고 뺀 날을
  /// 되돌린다
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

  /// 공개를 끄면 게스트 로그인도 끄고, 공개하면 이메일과 나만 보기를 지운다
  MeetingDraft withPublic(bool value) => MeetingDraft(
    mode: mode,
    dates: dates,
    startHour: startHour,
    endHour: endHour,
    isPublic: value,
    allowGuests: value && allowGuests,
    emails: value ? const [] : emails,
    domains: value ? const [] : domains,
    onlyMe: !value && onlyMe,
  );

  /// 공개가 아니면 게스트 로그인을 켜지 않는다
  MeetingDraft withGuests(bool value) =>
      isPublic ? _copy(allowGuests: value) : this;

  /// 비공개 모임에 이메일이나 도메인 [entry]를 더한다. 이미 있거나 공개면 그대로다
  MeetingDraft withAccessEntry(MeetingAccessEntry entry) {
    if (isPublic || emails.contains(entry.value)) return this;
    if (domains.contains(entry.value)) return this;
    return entry.domain
        ? _copy(domains: [...domains, entry.value])
        : _copy(emails: [...emails, entry.value]);
  }

  /// 넣은 이메일이나 도메인 [value]를 뺀다
  MeetingDraft withoutAccessEntry(String value) => _copy(
    emails: [
      for (final email in emails)
        if (email != value) email,
    ],
    domains: [
      for (final domain in domains)
        if (domain != value) domain,
    ],
  );

  /// 비공개 모임을 지금은 나만 볼지. 공개면 그대로다
  MeetingDraft withOnlyMe(bool value) => isPublic ? this : _copy(onlyMe: value);

  /// 넣은 이메일과 도메인의 수
  int get accessEntryCount => emails.length + domains.length;

  /// 누가 열 수 있는지 정했는지: 공개, 나만 보기, 또는 이메일·도메인 하나 이상
  bool get accessReady => isPublic || onlyMe || accessEntryCount > 0;

  /// 만든 뒤 보낼 공개 범위(`PUT /v1/visibility/meeting/{id}`): 공개(public), 나만 보기(private), 정한
  /// 이메일·도메인(allowed_emails, 빈 목록은 담지 않는다). 정하지 않았으면([accessReady]가 아니면) null
  VisibilityUpdate? get visibilityUpdate {
    if (isPublic) return const VisibilityUpdate(level: VisibilityLevel.public);
    if (onlyMe) return const VisibilityUpdate(level: VisibilityLevel.private);
    if (accessEntryCount == 0) return null;
    return VisibilityUpdate(
      level: VisibilityLevel.allowedEmails,
      allowedEmails: emails.isEmpty ? null : emails,
      allowedDomains: domains.isEmpty ? null : domains,
    );
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
    bool? allowGuests,
    List<String>? emails,
    List<String>? domains,
    bool? onlyMe,
  }) => MeetingDraft(
    mode: mode ?? this.mode,
    dates: dates ?? this.dates,
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    isPublic: isPublic,
    allowGuests: allowGuests ?? this.allowGuests,
    emails: emails ?? this.emails,
    domains: domains ?? this.domains,
    onlyMe: onlyMe ?? this.onlyMe,
  );
}
