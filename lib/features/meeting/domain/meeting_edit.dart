import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 모임 설정에서 고치는 것. 저장한 것과 저장하지 못한 것, 서버의 거절을 이 단위로 알린다
enum MeetingEditPart { title, dates, mode, time, visibility, guests }

/// 참여자가 이미 답을 넣었을 때 저장하기 전에 알리는 것
enum MeetingEditNotice {
  /// 받는 방식이 바뀌어 넣은 답이 다르게 보일 수 있다
  modeChanged,

  /// 원래 날 중 빠진 날이 있어 그날 넣은 답은 보이지 않는다
  daysDropped,
}

/// 모임을 누가 열 수 있는지(`GET /v1/visibility/meeting/{id}`). [level]을 모르면 null이다. 이메일·도메인은 서버에
/// 남아 있는 그대로다(공개 범위가 정한 이메일이 아니어도 남아 있을 수 있다)
@immutable
class MeetingAudience {
  const MeetingAudience(
    this.level, {
    this.emails = const [],
    this.domains = const [],
  });

  factory MeetingAudience.of(VisibilityRead read) => MeetingAudience(
    read.level,
    emails: read.allowedEmails,
    domains: read.allowedDomains,
  );

  final VisibilityLevel? level;
  final List<String> emails;
  final List<String> domains;
}

/// 저장 요청 하나와 그 요청이 저장하는 것
@immutable
sealed class MeetingEditStep {
  const MeetingEditStep(this.parts);

  final Set<MeetingEditPart> parts;
}

/// `PATCH /v1/meetings/{id}`. 바꾼 칸만 담는다(빈 칸은 보내지 않는다)
final class MeetingFieldsStep extends MeetingEditStep {
  const MeetingFieldsStep(this.body, super.parts);

  final MeetingUpdate body;
}

/// `PUT /v1/visibility/meeting/{id}`
final class MeetingVisibilityStep extends MeetingEditStep {
  const MeetingVisibilityStep(this.body)
    : super(const {MeetingEditPart.visibility});

  final VisibilityUpdate body;
}

/// 모임 설정의 처음 값: 지금 서버에 있는 미팅([meeting])과 공개 범위([audience]). 폼의 값([draft])과 비교해
/// 바뀐 것만 보낼 요청을 만든다([plan]).
///
/// 테스트: test/features/meeting/domain/meeting_edit_test.dart
@immutable
class MeetingEditBase {
  const MeetingEditBase({required this.meeting, required this.audience});

  final MeetingRead meeting;
  final MeetingAudience audience;

  bool get _hourly => meeting.mode == MeetingMode.hourly;

  /// 폼의 처음 값. 서버 값을 폼의 규칙으로 맞추지 않고 그대로 담는다(규칙에 맞지 않는 예전 모임도 그대로
  /// 보이고, 고치지 않으면 보내지 않는다). 시각은 정시로 읽고, 끝이 시작보다 이르거나 같으면 시작 한 시간
  /// 뒤까지로 보인다. 시간을 받지 않는 방식이면 시간별로 바꿀 때 쓸 처음 범위다. 공개 범위가 정한 이메일이
  /// 아니면 이메일·도메인은 비운다
  MeetingDraft get draft {
    final level = audience.level;
    final public = level == VisibilityLevel.public;
    final listed = level == VisibilityLevel.allowedEmails;
    final start = _hourOf(meeting.startTime);
    final end = switch (_hourOf(meeting.endTime)) {
      0 => 24,
      final hour when hour <= start => start + 1,
      final hour => hour,
    };
    return MeetingDraft(
      mode: meeting.mode,
      dates: MeetingDates.range(
        meeting.startDate,
        meeting.endDate,
        excluded: meeting.excludedDates,
      ),
      startHour: _hourly ? start : meetingDefaultStartHour,
      endHour: _hourly ? end : meetingDefaultEndHour,
      isPublic: public,
      allowGuests: public && meeting.allowGuests,
      emails: listed ? audience.emails : const [],
      domains: listed ? audience.domains : const [],
      onlyMe: level == VisibilityLevel.private,
    );
  }

  /// [next]가 공개 범위를 바꾸는지
  bool audienceChanged(MeetingDraft next) {
    final before = draft;
    return next.isPublic != before.isPublic ||
        next.onlyMe != before.onlyMe ||
        !setEquals(next.emails.toSet(), before.emails.toSet()) ||
        !setEquals(next.domains.toSet(), before.domains.toSet());
  }

  /// 폼의 값 [next]와 제목 [title]로 보낼 요청, 보내는 순서다. 바뀐 것이 없으면 비어 있고, 공개 범위를 바꿨는데
  /// 참여할 사람을 정하지 않았으면 null이다.
  ///
  /// 미팅 칸(제목·날짜·방식·시간)은 한 요청에 담는다. 기간이 바뀌면 새 기간에 맞는 제외 날짜를 함께 보내고,
  /// 시간별이 되거나 시간별에서 벗어나면 시각을 함께 보낸다(시간을 받지 않는 방식은 하루 전체). 게스트
  /// 로그인을 끄면 공개 범위보다 먼저, 켜면 공개 범위를 정한 뒤에 그 요청에 담는다(backend는 공개 미팅에서만
  /// 게스트를 켠다)
  List<MeetingEditStep>? plan(MeetingDraft next, {required String title}) {
    final before = draft;
    final hourly = next.mode == MeetingMode.hourly;
    final daysChanged = !listEquals(next.dates.days, before.dates.days);
    final periodChanged =
        daysChanged &&
        (next.dates.first != before.dates.first ||
            next.dates.last != before.dates.last);
    final timeChanged = hourly
        ? !_hourly ||
              next.startHour != before.startHour ||
              next.endHour != before.endHour
        : _hourly;
    final fields = <MeetingEditPart>{
      if (title != meeting.title) MeetingEditPart.title,
      if (daysChanged) MeetingEditPart.dates,
      if (next.mode != before.mode) MeetingEditPart.mode,
      if (timeChanged) MeetingEditPart.time,
    };
    final body = MeetingUpdate(
      title: fields.contains(MeetingEditPart.title) ? title : null,
      startDate: periodChanged ? next.dates.first : null,
      endDate: periodChanged ? next.dates.last : null,
      excludedDates: daysChanged ? next.dates.excluded : null,
      mode: fields.contains(MeetingEditPart.mode) ? next.mode : null,
      startTime: timeChanged ? clockOf(hourly ? next.startHour : 0) : null,
      endTime: timeChanged ? clockOf(hourly ? next.endHour : 0) : null,
    );
    final guests = next.allowGuests != before.allowGuests;
    final guestsOn = guests && next.allowGuests;
    MeetingVisibilityStep? visibility;
    if (audienceChanged(next)) {
      final update = _visibilityUpdate(next);
      if (update == null) return null;
      visibility = MeetingVisibilityStep(update);
    }
    final fieldsStep = fields.isEmpty && !guests
        ? null
        : MeetingFieldsStep(
            body.copyWith(allowGuests: guests ? next.allowGuests : null),
            {...fields, if (guests) MeetingEditPart.guests},
          );
    return [if (!guestsOn) ?fieldsStep, ?visibility, if (guestsOn) ?fieldsStep];
  }

  /// 저장하기 전에 알릴 것. 받는 방식이 바뀌었거나, 원래 날 중 빠진 날이 있다
  Set<MeetingEditNotice> notices(MeetingDraft next) {
    final before = draft;
    return {
      if (next.mode != before.mode) MeetingEditNotice.modeChanged,
      if (before.dates.days.any((day) => !next.dates.contains(day)))
        MeetingEditNotice.daysDropped,
    };
  }

  /// [next]의 공개 범위. 정한 이메일이면 서버에 남은 목록을 비울 때만 빈 목록을 보낸다
  VisibilityUpdate? _visibilityUpdate(MeetingDraft next) {
    final update = next.visibilityUpdate;
    if (update == null || update.level != VisibilityLevel.allowedEmails) {
      return update;
    }
    return update.copyWith(
      allowedEmails: next.emails.isEmpty && audience.emails.isEmpty
          ? null
          : next.emails,
      allowedDomains: next.domains.isEmpty && audience.domains.isEmpty
          ? null
          : next.domains,
    );
  }
}

int _hourOf(String clock) => int.tryParse(clock.split(':').first) ?? 0;
