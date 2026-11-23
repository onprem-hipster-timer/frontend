import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 앞의 답을 바꿔 뒤의 답을 묻지 않고 맞춘 것
enum MeetingAdjustment {
  /// 새 기간에 들지 않는 제외 날짜를 뺐다
  exclusionsDropped,

  /// 요일별이라 기간을 첫날부터 7일로 맞췄다
  weeklyPeriod,

  /// 요일별이라 제외 날짜를 되돌렸다
  weeklyExclusionsDropped,

  /// 요일별을 벗어나 요일별로 바꾸기 전의 날짜로 되돌렸다
  weeklyRestored,

  /// 요일별(기억한 날짜 없음)에서 시간별로 바꾸며 기간을 앞의 5일로 줄였다
  hourlyTrimmed,

  /// 시간별로 받을 수 없는 날짜가 되어 날짜별로 바꿨다
  hourlyToDaily,

  /// 이어진 7일이 아니게 되어 요일별을 날짜별로 바꿨다
  weeklyToDaily,

  /// 비공개라 게스트 답을 지웠다
  guestsDropped,

  /// 공개라 비공개에 참여할 사람(이메일·나만 보기) 답을 지웠다
  accessDropped,
}

/// 방식을 [before]에서 [after]로 바꾸며 묻지 않고 맞춘 것
Set<MeetingAdjustment> meetingModeAdjustments(
  MeetingDraft before,
  MeetingDraft after,
) {
  final weekly = after.mode == MeetingMode.weekly;
  final left =
      before.mode == MeetingMode.weekly &&
      !weekly &&
      !listEquals(before.dates.days, after.dates.days);
  return {
    if (weekly && after.dates.last != before.dates.last)
      MeetingAdjustment.weeklyPeriod,
    if (weekly && before.dates.excluded.isNotEmpty)
      MeetingAdjustment.weeklyExclusionsDropped,
    if (left && before.beforeWeekly != null) MeetingAdjustment.weeklyRestored,
    if (left && before.beforeWeekly == null) MeetingAdjustment.hourlyTrimmed,
  };
}
