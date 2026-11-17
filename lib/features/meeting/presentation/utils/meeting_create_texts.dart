import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/features/meeting/presentation/utils/meeting_formatters.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:momeet/shared/domain/terms.dart';

/// 모임 만들기에서 하나씩 묻는 질문의 문구

const meetingRangeQuestion = '언제 모일까요?';
const meetingRangeGuide = '시작하는 날과 끝나는 날을 눌러 주세요';
const meetingRangeOneDayHint = '하루만 모이면 같은 날을 두 번 눌러 주세요';

String meetingRangeStartedHint(DateTime start) =>
    '${meetingShortDay(start)}부터예요. 끝나는 날을 눌러 주세요';

const meetingExclusionQuestion = '이 범위에서 제외하고 싶은 날짜가 있나요?';
const meetingExclusionGuide = '빼고 싶은 날을 달력에서 눌러 주세요. 다시 누르면 돌아와요';
const meetingExclusionNone = '없어요';
const meetingExclusionDone = '다 골랐어요';
const meetingExcludeWeekends = '주말 제외';
const meetingRepickRange = '기간 다시 고르기';
const meetingEndsNotExcludable = '첫날과 마지막 날은 뺄 수 없어요';

const meetingModeQuestion = '어떻게 받을까요?';

/// 방식 고르기의 한 줄 설명
String meetingModeDescription(MeetingMode mode) => switch (mode) {
  MeetingMode.hourly => '고른 날마다 되는 시간을 받아요',
  MeetingMode.weekly => '매주 되는 요일을 받아요. 기간은 첫날부터 7일이에요',
  MeetingMode.daily || MeetingMode.$unknown => '되는 날만 받아요',
};

/// 시간별을 고를 수 없을 때의 까닭
const meetingHourlyUnavailable = '일주일 안에서 $hourlyMaxDays일까지만 받을 수 있어요';

/// 펼친 폼의 시간별 규칙
const meetingHourlyRule = '시간별은 $meetingHourlyUnavailable';

const meetingHoursQuestion =
    '$meetingDefaultStartHour시부터 $meetingDefaultEndHour시까지로 할까요?';
const meetingHoursPickQuestion = '몇 시부터 몇 시까지로 할까요?';
const meetingHoursGuide = '참여자는 이 시간 안에서 되는 시간을 칠해요';
const meetingYes = '예';
const meetingNo = '아니요';
const meetingHoursConfirm = '이 시간으로 할게요';

const meetingVisibilityExplain =
    '링크로 공유하면 링크가 있는 누구나 로그인 없이 보고 게스트로도 참여할 수 있어요. '
    '비공개는 정한 이메일로 로그인한 사람만 참여해요.';
const meetingVisibilityQuestion = '어떻게 할까요?';
const meetingPublic = '링크로 공유하기(공개)';
const meetingPrivate = '비공개';

const meetingGuestQuestion = '게스트를 허용할까요?';
const meetingGuestExplain =
    '가입하지 않은 사람도 닉네임과 비밀번호만으로 참여할 수 있어요. 다만 로그인보다 안전하지 않아요.';
const meetingAllowGuests = '허용';
const meetingRefuseGuests = '허용 안 함';

const meetingAccessQuestion = '참여할 사람의 이메일을 넣어 주세요';
const meetingAccessGuide = '이메일이나 회사·학교 도메인(example.com)을 하나씩 넣어 주세요';
const meetingAccessNote =
    '초대 메일은 보내지 않아요. 링크는 직접 전해 주세요. 받는 사람은 넣은 이메일로(도메인이면 그 도메인의 '
    '이메일로) 가입하거나 로그인해야 열 수 있어요.';
const meetingAccessFieldLabel = '이메일 또는 도메인';
const meetingAccessFieldHint = 'name@example.com 또는 example.com';
const meetingAccessAdd = '추가';
const meetingAccessRemove = '빼기';
const meetingAccessInvalid = '이메일이나 도메인 형식이 아니에요';
const meetingAccessDone = '다 넣었어요';
const meetingOnlyMe = '지금은 나만 볼게요';
const meetingOnlyMeExplain = '다른 사람은 참여할 수 없어요';
const meetingFormAccessTitle = '참여할 사람';
const meetingFormAccessRequired = "이메일을 하나 이상 넣거나 '지금은 나만 볼게요'를 골라야 만들 수 있어요";

const meetingTitleQuestion = '마지막으로 제목을 지어 주세요';
const meetingTitleGuide = '비워 두면 칸에 보이는 제목으로 만들어요';

const meetingKeepAnswer = '그대로 둘게요';
const meetingExpandAll = '전체 설정 펼치기';

/// 펼친 폼의 날짜 칸
const meetingFormDatesTitle = '${Terms.meeting} 날짜';
const meetingFormRangeSegment = '기간';
const meetingFormExcludeSegment = '제외할 날';
const meetingFormExcludeGuide = '빼고 싶은 날을 눌러 주세요';
const meetingFormWeeklyGuide = '시작하는 날을 누르면 그날부터 7일이에요';

/// 기간의 시작일만 누르고 만들려 할 때
const meetingRangeUnfinished = '끝나는 날을 골라 주세요';

/// 짧은 날짜 ('11.23(월)')
String meetingShortDay(DateTime day) =>
    '${day.month}.${day.day}(${weekdayName(weekdayNumber(day))})';

/// 기간 ('11.23(월)–11.27(금)', 하루면 '11.23(월)')
String meetingRangeText(MeetingDates dates) => dates.span == 1
    ? meetingShortDay(dates.first)
    : '${meetingShortDay(dates.first)}–${meetingShortDay(dates.last)}';

/// 기간 답 ('11.23(월)–11.27(금) · 5일')
String meetingRangeAnswer(MeetingDates dates) =>
    '${meetingRangeText(dates)} · ${dates.span}일';

/// 뺀 날 목록 ('제외: 11.25(수), 11.26(목)')
String meetingExcludedList(List<DateTime> days) =>
    '제외: ${days.map(meetingShortDay).join(', ')}';

/// 요약의 제외. 누르면 제외할 날을 다시 고른다 ('제외할 날 고르기', '제외한 날 다시 고르기')
String meetingExclusionSummary(MeetingDates dates) =>
    dates.excluded.isEmpty ? '제외할 날 고르기' : '제외한 날 다시 고르기';

/// 요약의 시간 ('6:00–18:00')
String meetingHoursSummary(MeetingDraft draft) =>
    '${draft.startHour}:00–${draft.endHour}:00';

/// 요약의 참여할 사람 ('나만', '이메일 2개', '도메인 1개', '이메일·도메인 3개')
String meetingAccessSummary(MeetingDraft draft) {
  if (draft.onlyMe) return '나만';
  final count = draft.accessEntryCount;
  if (draft.domains.isEmpty) return '이메일 $count개';
  if (draft.emails.isEmpty) return '도메인 $count개';
  return '이메일·도메인 $count개';
}

/// 비공개 모임의 링크를 누가 열 수 있는지 알리는 한 줄. 공개나 알 수 없으면 null
String? meetingLinkAudienceText(VisibilityLevel? level) => switch (level) {
  VisibilityLevel.allowedEmails => '정한 이메일로 로그인한 사람만 열 수 있어요',
  VisibilityLevel.private => '나만 볼 수 있어요',
  _ => null,
};

/// 요약의 게스트
String meetingGuestSummary(bool allowed) => allowed ? '게스트 허용' : '게스트 안 받음';

/// 앞의 답을 바꿔 뒤의 답을 맞춘 것을 알리는 문장
String meetingAdjustmentText(
  MeetingAdjustment adjustment,
  MeetingDraft draft,
) => switch (adjustment) {
  MeetingAdjustment.exclusionsDropped => '새 기간에 들지 않는 제외 날짜는 뺐어요',
  MeetingAdjustment.weeklyPeriod =>
    '요일별은 7일로 받아서 기간을 ${meetingRangeText(draft.dates).withJosa('으로', '로')} 맞췄어요',
  MeetingAdjustment.weeklyExclusionsDropped => '요일별이라 제외한 날짜를 되돌렸어요',
  MeetingAdjustment.hourlyToDaily => '이 날짜는 시간별로 받을 수 없어 날짜별로 바꿨어요',
  MeetingAdjustment.weeklyToDaily => '이어진 7일이 아니라서 요일별을 날짜별로 바꿨어요',
  MeetingAdjustment.guestsDropped => '비공개라 게스트는 받지 않아요',
  MeetingAdjustment.accessDropped => '링크로 공유해서 비공개 설정은 지웠어요',
};
