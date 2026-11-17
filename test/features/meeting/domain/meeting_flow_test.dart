import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

final today = DateTime.utc(2027, 2, 20);

/// 3월 [from]일과 [to]일을 차례로 누른 흐름
MeetingFlow ranged(
  int from,
  int to, [
  MeetingFlow flow = const MeetingFlow(),
]) => flow.tapDay(march(from)).tapDay(march(to));

/// 3월 [from]~[to]일을 고르고 제외 없이 [mode]까지 답한 흐름
MeetingFlow upToMode(int from, int to, MeetingMode mode) {
  final flow = ranged(from, to);
  return (flow.current == MeetingQuestion.exclusions
          ? flow.skipExclusions()
          : flow)
      .chooseMode(mode);
}

/// 모든 질문에 답한 흐름(시간별 5일, 공개, 게스트 허용)
MeetingFlow answeredAll() => upToMode(
  1,
  5,
  MeetingMode.hourly,
).acceptDefaultHours().choosePublic(true).chooseGuests(true);

void main() {
  group('하나씩 묻기', () {
    test('처음에는 기간만 묻는다', () {
      const flow = MeetingFlow();
      expect(flow.current, MeetingQuestion.range);
      expect(flow.summarized, isEmpty);
    });

    test('기본값이 있어도 답하기 전에는 다음 질문으로 가지 않는다', () {
      final started = const MeetingFlow().tapDay(march(3));
      expect(started.current, MeetingQuestion.range, reason: '끝나는 날을 아직 안 눌렀다');
      expect(started.rangeStart, march(3));

      final ranged = started.tapDay(march(5));
      expect(ranged.current, MeetingQuestion.exclusions);
      expect(ranged.isAnswered(MeetingQuestion.exclusions), isFalse);

      final excluded = ranged.skipExclusions();
      expect(excluded.current, MeetingQuestion.mode);
      expect(excluded.isAnswered(MeetingQuestion.mode), isFalse);

      final hourly = excluded.chooseMode(MeetingMode.hourly);
      expect(hourly.current, MeetingQuestion.time);

      final timed = hourly.acceptDefaultHours();
      expect(timed.current, MeetingQuestion.visibility);

      final public = timed.choosePublic(true);
      expect(public.current, MeetingQuestion.guests);

      final guests = public.chooseGuests(false);
      expect(guests.current, MeetingQuestion.title);
      expect(guests.summarized, [
        MeetingQuestion.range,
        MeetingQuestion.exclusions,
        MeetingQuestion.mode,
        MeetingQuestion.time,
        MeetingQuestion.visibility,
        MeetingQuestion.guests,
      ]);
    });

    test('답한 질문은 요약으로 남고 지금 질문은 요약에 없다', () {
      final flow = upToMode(1, 3, MeetingMode.daily);
      expect(flow.current, MeetingQuestion.visibility);
      expect(flow.summarized, [
        MeetingQuestion.range,
        MeetingQuestion.exclusions,
        MeetingQuestion.mode,
      ]);
    });
  });

  group('건너뛰는 질문', () {
    test('하루만 고르면 제외를 묻지 않는다', () {
      final flow = ranged(3, 3);
      expect(flow.current, MeetingQuestion.mode);
      expect(flow.applies(MeetingQuestion.exclusions), isFalse);
      expect(flow.summarized, [MeetingQuestion.range]);
    });

    test('날짜별·요일별은 시간을 묻지 않는다', () {
      expect(
        upToMode(1, 3, MeetingMode.daily).current,
        MeetingQuestion.visibility,
      );
      expect(
        upToMode(1, 3, MeetingMode.weekly).current,
        MeetingQuestion.visibility,
      );
    });

    test('비공개면 게스트를 묻지 않는다', () {
      final flow = upToMode(1, 3, MeetingMode.daily).choosePublic(false);
      expect(flow.current, MeetingQuestion.title);
      expect(flow.draft.allowGuests, isFalse);
      expect(flow.applies(MeetingQuestion.guests), isFalse);
    });
  });

  group('기간 고르기', () {
    test('시작일과 끝나는 날 사이를 모두 고른다', () {
      final dates = ranged(3, 6).draft.dates;
      expect(dates.first, march(3));
      expect(dates.last, march(6));
      expect(dates.days, hasLength(4));
      expect(dates.excluded, isEmpty);
    });

    test('끝나는 날을 앞에 누르면 앞의 날부터다', () {
      final dates = ranged(6, 3).draft.dates;
      expect(dates.first, march(3));
      expect(dates.last, march(6));
    });

    test('같은 날을 두 번 누르면 하루다', () {
      final dates = ranged(3, 3).draft.dates;
      expect(dates.days, [march(3)]);
    });

    test('기간을 다시 고를 때 첫 탭은 새 시작일이다', () {
      final flow = ranged(3, 6).skipExclusions().edit(MeetingQuestion.range);
      final restarted = flow.tapDay(march(10));
      expect(restarted.rangeStart, march(10));
      expect(restarted.current, MeetingQuestion.range);
      expect(restarted.tapDay(march(12)).draft.dates.first, march(10));
    });
  });

  group('제외', () {
    test('기간 안의 날을 누르면 빼고 다시 누르면 되돌리며, 다 골랐어요로 답한다', () {
      var flow = ranged(1, 5).tapDay(march(2)).tapDay(march(3));
      expect(flow.draft.dates.excluded, [march(2), march(3)]);
      expect(flow.current, MeetingQuestion.exclusions, reason: '아직 답하지 않았다');

      flow = flow.tapDay(march(3));
      expect(flow.draft.dates.excluded, [march(2)]);

      flow = flow.confirmExclusions();
      expect(flow.current, MeetingQuestion.mode);
      expect(flow.draft.dates.excluded, [march(2)]);
    });

    test('첫날과 마지막 날은 뺄 수 없다', () {
      final flow = ranged(1, 5);
      expect(flow.tapDay(march(1)).draft.dates.excluded, isEmpty);
      expect(flow.tapDay(march(5)).draft.dates.excluded, isEmpty);
      expect(flow.draft.dates.canExclude(march(1)), isFalse);
    });

    test('없어요는 뺀 날 없이 답한다', () {
      final flow = ranged(1, 5).tapDay(march(3)).skipExclusions();
      expect(flow.draft.dates.excluded, isEmpty);
      expect(flow.current, MeetingQuestion.mode);
    });

    test('주말 제외는 가운데 주말을 빼고 아직 답하지 않는다', () {
      final flow = ranged(1, 14).excludeWeekends();
      expect(flow.draft.dates.excluded, [march(6), march(7), march(13)]);
      expect(flow.current, MeetingQuestion.exclusions);
    });

    test('만들기 요청의 기간과 제외 날짜가 고른 그대로다', () {
      final body = ranged(1, 7)
          .tapDay(march(3))
          .confirmExclusions()
          .chooseMode(MeetingMode.daily)
          .draft
          .toMeetingCreate(title: 't', timezone: 'Asia/Seoul');
      expect(body.startDate, march(1));
      expect(body.endDate, march(7));
      expect(body.excludedDates, [march(3)]);
      expect(body.mode, MeetingMode.daily);
    });
  });

  group('받는 방식', () {
    test('시간별을 고를 수 없는 날짜면 시간별을 골라도 그대로다', () {
      final flow = ranged(1, 6).skipExclusions();
      expect(flow.draft.hourlyAvailable, isFalse);
      final tapped = flow.chooseMode(MeetingMode.hourly);
      expect(tapped.current, MeetingQuestion.mode);
      expect(tapped.isAnswered(MeetingQuestion.mode), isFalse);
    });

    test('가운데 날을 빼 5일이 되면 시간별을 고를 수 있다', () {
      final flow = ranged(4, 10)
          .tapDay(march(6))
          .tapDay(march(7))
          .confirmExclusions()
          .chooseMode(MeetingMode.hourly);
      expect(flow.draft.mode, MeetingMode.hourly);
      expect(flow.current, MeetingQuestion.time);
    });

    test('요일별은 시작일부터 7일로 맞추고 뺀 날을 되돌리며, 무엇을 바꿨는지 남긴다', () {
      final flow = ranged(
        1,
        4,
      ).tapDay(march(2)).confirmExclusions().chooseMode(MeetingMode.weekly);
      expect(flow.draft.dates.first, march(1));
      expect(flow.draft.dates.last, march(7));
      expect(flow.draft.dates.excluded, isEmpty);
      expect(flow.adjusted, {
        MeetingAdjustment.weeklyPeriod,
        MeetingAdjustment.weeklyExclusionsDropped,
      });
      expect(flow.applies(MeetingQuestion.exclusions), isFalse);
    });

    test('이미 이어진 7일이면 요일별로 바꿔도 바꾼 것이 없다', () {
      final flow = upToMode(1, 7, MeetingMode.weekly);
      expect(flow.adjusted, isEmpty);
    });

    test('다음 답을 하면 바꾼 것 알림이 사라진다', () {
      final flow = ranged(1, 4).skipExclusions().chooseMode(MeetingMode.weekly);
      expect(flow.adjusted, isNotEmpty);
      expect(flow.choosePublic(true).adjusted, isEmpty);
    });
  });

  group('시간', () {
    test('예는 6시~18시로 답한다', () {
      final flow = upToMode(1, 3, MeetingMode.hourly).acceptDefaultHours();
      expect(flow.draft.startHour, 6);
      expect(flow.draft.endHour, 18);
      expect(flow.current, MeetingQuestion.visibility);
    });

    test('아니요는 시각을 고르게 하고, 정하면 답한다', () {
      var flow = upToMode(1, 3, MeetingMode.hourly).pickHours();
      expect(flow.pickingHours, isTrue);
      expect(flow.current, MeetingQuestion.time);
      flow = flow.withStartHour(9).withEndHour(21);
      expect(flow.current, MeetingQuestion.time, reason: '정하기 전에는 그대로다');
      flow = flow.confirmHours();
      expect(flow.current, MeetingQuestion.visibility);
      expect(flow.pickingHours, isFalse);
      expect(flow.draft.startHour, 9);
      expect(flow.draft.endHour, 21);
    });
  });

  group('앞 답 바꾸기', () {
    test('요약을 누르면 그 질문을 다시 묻고 뒤의 답은 요약으로 남는다', () {
      final flow = answeredAll().edit(MeetingQuestion.mode);
      expect(flow.current, MeetingQuestion.mode);
      expect(flow.summarized, isNot(contains(MeetingQuestion.mode)));
      expect(flow.summarized, contains(MeetingQuestion.visibility));
    });

    test('그대로 둘게요는 바꾸던 것을 버리고 하던 질문으로 돌아간다', () {
      final editing = answeredAll()
          .edit(MeetingQuestion.exclusions)
          .tapDay(march(3));
      expect(editing.draft.dates.excluded, [march(3)]);
      final kept = editing.keep();
      expect(kept.draft.dates.excluded, isEmpty);
      expect(kept.current, MeetingQuestion.title);

      final restarted = answeredAll()
          .edit(MeetingQuestion.range)
          .tapDay(march(9));
      expect(restarted.keep().draft.dates.first, march(1));
      expect(restarted.keep().rangeStart, isNull);
    });

    test('기간을 줄이면 밖으로 나간 제외 날짜를 빼고 알린다', () {
      final flow = ranged(1, 7)
          .tapDay(march(3))
          .tapDay(march(6))
          .confirmExclusions()
          .chooseMode(MeetingMode.daily)
          .choosePublic(false)
          .edit(MeetingQuestion.range)
          .tapDay(march(1))
          .tapDay(march(4));
      expect(flow.draft.dates.excluded, [march(3)]);
      expect(flow.adjusted, {MeetingAdjustment.exclusionsDropped});
      expect(flow.current, MeetingQuestion.title, reason: '모두 답했다');
    });

    test('시간별로 받을 수 없는 기간으로 바꾸면 날짜별로 바꾸고 시간을 묻지 않는다', () {
      final flow = answeredAll()
          .edit(MeetingQuestion.range)
          .tapDay(march(1))
          .tapDay(march(10));
      expect(flow.draft.mode, MeetingMode.daily);
      expect(flow.adjusted, contains(MeetingAdjustment.hourlyToDaily));
      expect(flow.applies(MeetingQuestion.time), isFalse);
    });

    test('기간을 늘려 제외를 아직 답하지 않았으면 제외를 묻는다', () {
      final flow = ranged(3, 3)
          .chooseMode(MeetingMode.daily)
          .choosePublic(false)
          .edit(MeetingQuestion.range)
          .tapDay(march(3))
          .tapDay(march(6));
      expect(flow.current, MeetingQuestion.exclusions);
    });

    test('요일별에서 7일이 아닌 기간으로 바꾸면 날짜별로 바꾼다', () {
      final flow = upToMode(1, 7, MeetingMode.weekly)
          .choosePublic(false)
          .edit(MeetingQuestion.range)
          .tapDay(march(1))
          .tapDay(march(3));
      expect(flow.draft.mode, MeetingMode.daily);
      expect(flow.adjusted, contains(MeetingAdjustment.weeklyToDaily));
    });

    test('비공개로 바꾸면 게스트 답을 지우고 알리며, 다시 공개하면 게스트를 묻는다', () {
      final private = answeredAll()
          .edit(MeetingQuestion.visibility)
          .choosePublic(false);
      expect(private.draft.allowGuests, isFalse);
      expect(private.adjusted, {MeetingAdjustment.guestsDropped});
      expect(private.summarized, isNot(contains(MeetingQuestion.guests)));
      expect(private.current, MeetingQuestion.title);

      final public = private
          .edit(MeetingQuestion.visibility)
          .choosePublic(true);
      expect(public.current, MeetingQuestion.guests);
    });

    test('날짜별에서 시간별로 바꾸면 시간을 묻는다', () {
      final flow = upToMode(1, 3, MeetingMode.daily)
          .choosePublic(false)
          .edit(MeetingQuestion.mode)
          .chooseMode(MeetingMode.hourly);
      expect(flow.current, MeetingQuestion.time);
    });
  });

  group('전체 설정 펼치기', () {
    test('답하지 않은 설정은 기본값(시간별 6~18시, 공개, 게스트 허용)으로 채운다', () {
      final flow = ranged(1, 3).expand();
      expect(flow.expanded, isTrue);
      expect(flow.draft.mode, MeetingMode.hourly);
      expect(flow.draft.startHour, 6);
      expect(flow.draft.endHour, 18);
      expect(flow.draft.isPublic, isTrue);
      expect(flow.draft.allowGuests, isTrue);
      expect(flow.draft.dates.excluded, isEmpty);
    });

    test('시간별을 고를 수 없는 날짜면 날짜별로 채운다', () {
      expect(ranged(1, 10).expand().draft.mode, MeetingMode.daily);
    });

    test('답한 설정은 그대로 둔다', () {
      final flow = upToMode(
        1,
        3,
        MeetingMode.weekly,
      ).choosePublic(false).expand();
      expect(flow.draft.mode, MeetingMode.weekly);
      expect(flow.draft.isPublic, isFalse);
      expect(flow.draft.allowGuests, isFalse);
    });

    test('공개를 다시 켜 게스트를 아직 답하지 않았으면 게스트 허용으로 채운다', () {
      final flow = upToMode(1, 3, MeetingMode.daily)
          .choosePublic(false)
          .edit(MeetingQuestion.visibility)
          .choosePublic(true)
          .expand();
      expect(flow.draft.allowGuests, isTrue);
    });

    test('날짜를 고르기 전에도 펼칠 수 있고 기간은 비어 있다', () {
      final flow = const MeetingFlow().expand();
      expect(flow.expanded, isTrue);
      expect(flow.draft.dates.isEmpty, isTrue);
    });

    test('펼친 폼의 달력은 두 번 눌러 기간을, 제외 모드면 그날을 빼거나 되돌린다', () {
      var flow = const MeetingFlow().expand();
      flow = flow.tapDayInForm(march(1), excluding: false);
      expect(flow.rangeStart, march(1));
      flow = flow.tapDayInForm(march(5), excluding: false);
      expect(flow.draft.dates.span, 5);
      flow = flow.tapDayInForm(march(3), excluding: true);
      expect(flow.draft.dates.excluded, [march(3)]);
      flow = flow.tapDayInForm(march(1), excluding: true);
      expect(flow.draft.dates.excluded, [march(3)], reason: '첫날은 뺄 수 없다');
    });

    test('펼친 폼에서 시간별로 받을 수 없는 기간을 고르면 날짜별로 바꾼다', () {
      final flow = const MeetingFlow()
          .expand()
          .tapDayInForm(march(1), excluding: false)
          .tapDayInForm(march(10), excluding: false);
      expect(flow.draft.mode, MeetingMode.daily);
    });

    test('펼친 폼의 요일별은 누른 날부터 7일이다', () {
      final flow = const MeetingFlow()
          .expand()
          .withDraft(const MeetingDraft(mode: MeetingMode.weekly))
          .tapDayInForm(march(3), excluding: false);
      expect(flow.draft.dates.first, march(3));
      expect(flow.draft.dates.isWeek, isTrue);
      expect(flow.rangeStart, isNull);
    });
  });

  group('되살리기', () {
    test('답한 질문을 요약하고 첫 미답 질문부터 묻는다', () {
      final draft = const MeetingDraft(
        mode: MeetingMode.daily,
      ).withDates(MeetingDates.range(march(1), march(3)));
      final flow = MeetingFlow.restored(
        draft,
        answered: {MeetingQuestion.range, MeetingQuestion.exclusions},
      );
      expect(flow.current, MeetingQuestion.mode);
      expect(flow.summarized, [
        MeetingQuestion.range,
        MeetingQuestion.exclusions,
      ]);
      expect(flow.expanded, isFalse);
    });

    test('답한 질문을 모르면 펼친 폼으로 되살린다', () {
      final flow = MeetingFlow.restored(const MeetingDraft());
      expect(flow.expanded, isTrue);
    });
  });

  group('날짜 칸 상태', () {
    test('지난 날은 고를 수 없다', () {
      const flow = MeetingFlow();
      expect(
        flow.dayState(DateTime.utc(2027, 2, 19), today: today),
        MeetingDayState.unavailable,
      );
      expect(
        flow.dayState(DateTime.utc(2027, 2, 20), today: today),
        MeetingDayState.open,
      );
    });

    test('시작일을 누르면 그날만 고른 상태이고, 3개월 상한 밖은 고를 수 없다', () {
      final flow = const MeetingFlow().tapDay(march(31));
      expect(flow.dayState(march(31), today: today), MeetingDayState.selected);
      expect(
        flow.dayState(DateTime.utc(2027, 6, 30), today: today),
        MeetingDayState.open,
      );
      expect(
        flow.dayState(DateTime.utc(2027, 7, 1), today: today),
        MeetingDayState.unavailable,
      );
    });

    test('제외를 묻는 동안 기간 밖은 고를 수 없고 뺀 날은 뺀 상태다', () {
      final flow = ranged(1, 5).tapDay(march(3));
      expect(flow.dayState(march(3), today: today), MeetingDayState.excluded);
      expect(flow.dayState(march(1), today: today), MeetingDayState.selected);
      expect(
        flow.dayState(march(6), today: today),
        MeetingDayState.unavailable,
      );
    });

    test('펼친 폼은 제외 모드일 때만 기간 밖을 막는다', () {
      final flow = ranged(1, 5).expand();
      expect(
        flow.dayState(march(6), today: today, excluding: true),
        MeetingDayState.unavailable,
      );
      expect(
        flow.dayState(march(6), today: today, excluding: false),
        MeetingDayState.open,
      );
    });
  });
}
