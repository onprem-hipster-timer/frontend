import 'package:flutter/foundation.dart';
import 'package:momeet/features/meeting/domain/meeting_access.dart';
import 'package:momeet/features/meeting/domain/meeting_adjustment.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/shared/api/rest/export.dart';

export 'package:momeet/features/meeting/domain/meeting_adjustment.dart';

/// 모임 만들기에서 하나씩 묻는 질문. 묻는 순서다
enum MeetingQuestion {
  range,
  exclusions,
  mode,
  time,
  visibility,
  guests,
  access,
  title,
}

/// 달력의 날짜 칸 상태
enum MeetingDayState {
  /// 누를 수 있다
  open,

  /// 고른 날
  selected,

  /// 기간을 고르는 중의 시작일. 끝나는 날을 누르기를 기다린다
  started,

  /// 기간 안에서 뺀 날
  excluded,

  /// 누를 수 없다(지난 날, 기간 상한 밖, 제외를 고를 때 기간 밖)
  unavailable,
}

/// 모임 만들기를 한 번에 한 질문씩 묻는 흐름. 다음 질문은 지금 질문에 답해야 나오고, 기본값이 있어도 먼저
/// 나오지 않는다. 답한 질문은 요약으로 남아 다시 고를 수 있고([edit]), 앞의 답을 바꾸면 뒤의 답을 묻지 않고
/// 맞춘 뒤 무엇을 맞췄는지 남긴다([adjusted]). [expanded]면 모든 설정을 한 폼으로 보인다.
///
/// 테스트: test/features/meeting/domain/meeting_flow_test.dart
@immutable
class MeetingFlow {
  const MeetingFlow({
    this.draft = const MeetingDraft(),
    this.answered = const {},
    this.rangeStart,
    this.editing,
    this.pickingHours = false,
    this.adjusted = const {},
    this.expanded = false,
    this.before,
  });

  /// 이 기기에 두었던 폼을 되살린다. [answered]를 모르면(펼친 폼에서 둔 폼) 펼친 폼이다. 비공개인데 참여할
  /// 사람을 정하지 않은 값이면 그 질문은 답하지 않은 것으로 둔다
  factory MeetingFlow.restored(
    MeetingDraft draft, {
    Set<MeetingQuestion>? answered,
  }) => answered == null
      ? MeetingFlow(draft: draft, expanded: true)
      : MeetingFlow(
          draft: draft,
          answered: {...answered}
            ..removeWhere(
              (q) => q == MeetingQuestion.access && !draft.accessReady,
            ),
        );

  final MeetingDraft draft;

  /// 답한 질문(지금은 묻지 않는 질문의 답도 남는다. 다시 물을 때 쓴다)
  final Set<MeetingQuestion> answered;

  /// 기간을 고르는 중 먼저 누른 날. 끝나는 날을 누르면 null이다
  final DateTime? rangeStart;

  /// 요약을 눌러 다시 묻는 질문
  final MeetingQuestion? editing;

  /// 시간을 '아니요'로 답해 시각을 고르는 중
  final bool pickingHours;

  /// 마지막 답으로 묻지 않고 맞춘 것. 다음 답에서 지운다
  final Set<MeetingAdjustment> adjusted;

  /// 모든 설정을 한 폼으로 보인다
  final bool expanded;

  /// 다시 묻기 전의 값([keep]이 되돌린다)
  final MeetingDraft? before;

  bool get _modeChosen => answered.contains(MeetingQuestion.mode);

  /// [question]을 지금 값에서 묻는지
  bool applies(MeetingQuestion question) => switch (question) {
    MeetingQuestion.exclusions =>
      answered.contains(MeetingQuestion.range) &&
          draft.dates.span > 1 &&
          !(_modeChosen && draft.mode == MeetingMode.weekly),
    MeetingQuestion.time => _modeChosen && draft.mode == MeetingMode.hourly,
    MeetingQuestion.guests =>
      answered.contains(MeetingQuestion.visibility) && draft.isPublic,
    MeetingQuestion.access =>
      answered.contains(MeetingQuestion.visibility) && !draft.isPublic,
    _ => true,
  };

  /// [question]에 답했고 지금 값에서 묻는 질문인지
  bool isAnswered(MeetingQuestion question) =>
      answered.contains(question) && applies(question);

  /// 지금 묻는 질문: 다시 묻는 질문, 아니면 답하지 않은 첫 질문(모두 답했으면 제목)
  MeetingQuestion get current =>
      editing ??
      MeetingQuestion.values.firstWhere(
        (question) =>
            question == MeetingQuestion.title ||
            (applies(question) && !answered.contains(question)),
      );

  /// 요약으로 보일 답한 질문, 묻는 순서
  List<MeetingQuestion> get summarized => [
    for (final question in MeetingQuestion.values)
      if (question != current && isAnswered(question)) question,
  ];

  /// 달력의 [day]를 누른다. 기간을 물으면 시작일·끝나는 날을 차례로 고르고(끝나는 날로 답한다), 제외를 물으면
  /// 그날을 빼거나 되돌린다(첫날·마지막 날은 그대로)
  MeetingFlow tapDay(DateTime day) => switch (current) {
    MeetingQuestion.range => _pickRange(calendarDay(day)),
    MeetingQuestion.exclusions => _copy(
      draft: draft.withDates(draft.dates.toggleExcluded(day)),
    ),
    _ => this,
  };

  MeetingFlow _pickRange(DateTime day) {
    final start = rangeStart;
    if (start == null) return _copy(rangeStart: day);
    final previous = draft.dates.excluded;
    final next = MeetingDates.range(start, day, excluded: previous);
    return _answer(
      MeetingQuestion.range,
      draft.withDates(next),
      adjusted: {
        if (next.excluded.length < previous.length)
          MeetingAdjustment.exclusionsDropped,
      },
    );
  }

  /// 제외 '없어요': 뺀 날 없이 답한다
  MeetingFlow skipExclusions() => _answer(
    MeetingQuestion.exclusions,
    draft.withDates(draft.dates.withoutExclusions()),
  );

  /// 제외 '다 골랐어요'
  MeetingFlow confirmExclusions() => _answer(MeetingQuestion.exclusions, draft);

  /// 뺄 수 있는 주말을 모두 뺀다(답하지는 않는다)
  MeetingFlow excludeWeekends() =>
      _copy(draft: draft.withDates(draft.dates.withoutWeekends()));

  /// 방식을 고른다. 시간별을 받을 수 없는 날짜면 그대로다. 요일별은 첫날부터 7일로 맞추고 뺀 날을 되돌리며,
  /// 요일별을 벗어나면 그전 날짜로 되돌리거나 시간별 기간으로 줄인다([MeetingDraft.withMode])
  MeetingFlow chooseMode(MeetingMode mode) {
    if (mode == MeetingMode.hourly && !draft.hourlyAvailable) return this;
    final next = draft.withMode(mode);
    return _answer(
      MeetingQuestion.mode,
      next,
      adjusted: meetingModeAdjustments(draft, next),
    );
  }

  /// 펼친 폼(모임 설정 포함)에서 방식을 바꾼다. 시간별을 받을 수 없는 날짜면 그대로이고, 묻지 않고 맞춘 것을
  /// 남긴다(다음에 값을 바꾸면 지운다)
  MeetingFlow changeMode(MeetingMode mode) {
    final next = draft.withMode(mode);
    if (identical(next, draft)) return this;
    return MeetingFlow(
      draft: next,
      expanded: expanded,
      adjusted: meetingModeAdjustments(draft, next),
    );
  }

  /// 시간 '예': 처음 값(6~18시)으로 답한다
  MeetingFlow acceptDefaultHours() => _answer(
    MeetingQuestion.time,
    draft
        .withStartHour(meetingDefaultStartHour)
        .withEndHour(meetingDefaultEndHour),
  );

  /// 시간 '아니요': 시각을 고르게 한다
  MeetingFlow pickHours() => _copy(pickingHours: true);

  MeetingFlow withStartHour(int hour) =>
      _copy(draft: draft.withStartHour(hour));

  MeetingFlow withEndHour(int hour) => _copy(draft: draft.withEndHour(hour));

  /// 고른 시각으로 답한다
  MeetingFlow confirmHours() => _answer(MeetingQuestion.time, draft);

  /// 공개 여부를 답한다. 비공개면 게스트 답을, 공개면 참여할 사람 답을 지우고(다시 바꾸면 다시 묻는다), 지웠으면
  /// 알린다
  MeetingFlow choosePublic(bool value) {
    final dropped = value
        ? isAnswered(MeetingQuestion.access)
        : isAnswered(MeetingQuestion.guests);
    final next = _answer(
      MeetingQuestion.visibility,
      draft.withPublic(value),
      adjusted: {
        if (dropped && value) MeetingAdjustment.accessDropped,
        if (dropped && !value) MeetingAdjustment.guestsDropped,
      },
    );
    return next._copy(
      answered: {...next.answered}
        ..remove(value ? MeetingQuestion.access : MeetingQuestion.guests),
    );
  }

  MeetingFlow chooseGuests(bool value) =>
      _answer(MeetingQuestion.guests, draft.withGuests(value));

  /// 비공개 모임에 이메일이나 도메인 [entry]를 더한다(이미 있으면 그대로, 답하지는 않는다)
  MeetingFlow addAccessEntry(MeetingAccessEntry entry) =>
      _copy(draft: draft.withAccessEntry(entry));

  /// 넣은 이메일이나 도메인 [value]를 뺀다
  MeetingFlow removeAccessEntry(String value) =>
      _copy(draft: draft.withoutAccessEntry(value));

  /// '다 넣었어요': 넣은 이메일·도메인으로 답한다. 하나도 없으면 그대로다
  MeetingFlow confirmAccess() => draft.accessEntryCount == 0
      ? this
      : _answer(MeetingQuestion.access, draft.withOnlyMe(false));

  /// '지금은 나만 볼게요': 나만 보는 비공개로 답한다
  MeetingFlow keepPrivate() =>
      _answer(MeetingQuestion.access, draft.withOnlyMe(true));

  /// 답한 [question]을 다시 묻는다
  MeetingFlow edit(MeetingQuestion question) => MeetingFlow(
    draft: draft,
    answered: answered,
    editing: question,
    before: draft,
  );

  /// 다시 묻던 질문을 바꾸지 않고 닫는다
  MeetingFlow keep() => MeetingFlow(draft: before ?? draft, answered: answered);

  /// 모든 설정을 한 폼으로 펼친다. 답하지 않은 설정은 처음 값으로 둔다: 제외 없음(이미 뺀 날은 그대로), 시간별
  /// 6~18시(받을 수 없는 날짜면 날짜별), 공개, 게스트 허용
  MeetingFlow expand() {
    var next = draft;
    if (!_modeChosen && !next.hourlyAvailable) {
      next = next.withMode(MeetingMode.daily);
    }
    if (!answered.contains(MeetingQuestion.guests) && next.isPublic) {
      next = next.withGuests(true);
    }
    return MeetingFlow(draft: next, rangeStart: rangeStart, expanded: true);
  }

  /// 펼친 폼에서 [day]를 누른다. [excluding]이면 그날을 빼거나 되돌리고, 아니면 기간을 고른다(요일별은 그날부터
  /// 7일). 시간별을 받을 수 없는 날짜가 되면 날짜별로 바꾼다
  MeetingFlow tapDayInForm(DateTime day, {required bool excluding}) {
    final target = calendarDay(day);
    if (excluding) {
      return _copy(draft: draft.withDates(draft.dates.toggleExcluded(target)));
    }
    if (draft.mode == MeetingMode.weekly) {
      return withDraft(
        draft.withDates(MeetingDates.period(target, weeklyDays)),
      );
    }
    final start = rangeStart;
    if (start == null) return _copy(rangeStart: target);
    var next = draft.withDates(
      MeetingDates.range(start, target, excluded: draft.dates.excluded),
    );
    if (next.mode == MeetingMode.hourly && !next.hourlyAvailable) {
      next = next.withMode(MeetingMode.daily);
    }
    return withDraft(next);
  }

  /// 펼친 폼의 값을 바꾼다
  MeetingFlow withDraft(MeetingDraft next) =>
      MeetingFlow(draft: next, expanded: expanded);

  /// [today] 기준 [day] 칸의 상태. [excluding]을 주지 않으면 제외를 묻는 동안 제외 달력이다
  MeetingDayState dayState(
    DateTime day, {
    required DateTime today,
    bool? excluding,
  }) {
    final target = calendarDay(day);
    final dates = draft.dates;
    if (target.isBefore(calendarDay(today))) return MeetingDayState.unavailable;
    if (excluding ?? current == MeetingQuestion.exclusions) {
      if (!dates.inPeriod(target)) return MeetingDayState.unavailable;
      return dates.contains(target)
          ? MeetingDayState.selected
          : MeetingDayState.excluded;
    }
    final start = rangeStart;
    if (start != null) {
      if (target == start) return MeetingDayState.started;
      return MeetingDates.range(start, target).withinMaxPeriod
          ? MeetingDayState.open
          : MeetingDayState.unavailable;
    }
    if (dates.contains(target)) return MeetingDayState.selected;
    if (dates.inPeriod(target)) return MeetingDayState.excluded;
    return MeetingDayState.open;
  }

  /// [question]에 [next] 값으로 답한다. 다시 묻던 것을 닫고, 방식이 새 날짜에 맞지 않으면 날짜별로 바꾼다
  MeetingFlow _answer(
    MeetingQuestion question,
    MeetingDraft next, {
    Set<MeetingAdjustment> adjusted = const {},
  }) {
    final changes = {...adjusted};
    var settled = next;
    if (_modeChosen || question == MeetingQuestion.mode) {
      if (settled.mode == MeetingMode.hourly && !settled.hourlyAvailable) {
        settled = settled.withMode(MeetingMode.daily);
        changes.add(MeetingAdjustment.hourlyToDaily);
      } else if (settled.mode == MeetingMode.weekly && !settled.dates.isWeek) {
        settled = settled.withMode(MeetingMode.daily);
        changes.add(MeetingAdjustment.weeklyToDaily);
      }
    }
    return MeetingFlow(
      draft: settled,
      answered: {...answered, question},
      adjusted: changes,
    );
  }

  MeetingFlow _copy({
    MeetingDraft? draft,
    Set<MeetingQuestion>? answered,
    DateTime? rangeStart,
    bool? pickingHours,
  }) => MeetingFlow(
    draft: draft ?? this.draft,
    answered: answered ?? this.answered,
    rangeStart: rangeStart ?? this.rangeStart,
    editing: editing,
    pickingHours: pickingHours ?? this.pickingHours,
    adjusted: adjusted,
    expanded: expanded,
    before: before,
  );
}
