import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/shared/api/rest/export.dart';

/// 2027년 3월의 [day]일(3월 1일은 월요일). 32일 이상이면 4월로 넘어간다
DateTime march(int day) => DateTime.utc(2027, 3, day);

/// 3월 [from]~[to]일 중 [kept] 날만 모이는 날짜(나머지는 뺀 날)
MeetingDates only(int from, int to, Set<int> kept) => MeetingDates.range(
  march(from),
  march(to),
  excluded: [
    for (var day = from; day <= to; day++)
      if (!kept.contains(day)) march(day),
  ],
);

void main() {
  group('시간별은 모이는 날이 5일 이하면 기간과 상관없이 받는다', () {
    test('5일이 3주에 걸쳐 있어도 시간별로 받을 수 있다', () {
      final draft = MeetingDraft(
        mode: MeetingMode.daily,
        dates: only(1, 19, {1, 8, 10, 15, 19}),
      );
      expect(draft.dates.span, 19);
      expect(draft.hourlyAvailable, isTrue);
      expect(draft.withMode(MeetingMode.hourly).mode, MeetingMode.hourly);
    });

    test('모이는 날이 6일이면 기간이 짧아도 시간별로 받을 수 없다', () {
      final draft = MeetingDraft(
        mode: MeetingMode.daily,
        dates: MeetingDates.range(march(1), march(6)),
      );
      expect(draft.hourlyAvailable, isFalse);
      expect(draft.withMode(MeetingMode.hourly).mode, MeetingMode.daily);
    });

    test('긴 기간도 뺀 날로 5일이 되면 시간별로 받을 수 있다', () {
      final draft = MeetingDraft(
        mode: MeetingMode.daily,
        dates: only(2, 30, {2, 9, 16, 23, 30}),
      );
      expect(draft.hourlyAvailable, isTrue);
      expect(
        draft.withDates(draft.dates.toggleExcluded(march(3))).hourlyAvailable,
        isFalse,
        reason: '6일',
      );
    });

    test('3주에 걸친 5일 시간별 모임의 만들기 요청은 첫날~마지막 날과 그 사이 뺀 날이다', () {
      final draft = MeetingDraft(
        mode: MeetingMode.daily,
        dates: only(1, 19, {1, 8, 10, 15, 19}),
      ).withMode(MeetingMode.hourly);
      final body = draft.toMeetingCreate(title: '스터디', timezone: 'Asia/Seoul');

      expect(body.mode, MeetingMode.hourly);
      expect(body.startDate, march(1));
      expect(body.endDate, march(19));
      expect(body.excludedDates, hasLength(14));
      expect(body.excludedDates, isNot(contains(march(8))));
      expect((body.startTime, body.endTime), ('06:00:00', '18:00:00'));
    });

    test('둔 폼을 되살려도 3주에 걸친 5일 시간별은 시간별이다', () {
      final restored = MeetingDraft.restore(
        mode: MeetingMode.hourly,
        days: only(1, 19, {1, 8, 10, 15, 19}).days,
        startHour: 9,
        endHour: 18,
        isPublic: true,
        allowGuests: true,
        today: DateTime.utc(2027, 2, 1),
      )!;
      expect(restored.mode, MeetingMode.hourly);
      expect(restored.dates.days, hasLength(5));
    });

    test('질문 흐름에서 기간을 길게 고르고 5일만 남기면 시간별을 고를 수 있다', () {
      var flow = const MeetingFlow().tapDay(march(1)).tapDay(march(15));
      for (var day = 2; day <= 14; day++) {
        if (!{4, 8, 11}.contains(day)) flow = flow.tapDay(march(day));
      }
      flow = flow.confirmExclusions();
      expect(flow.draft.dates.days, hasLength(5));
      final chosen = flow.chooseMode(MeetingMode.hourly);
      expect(chosen.isAnswered(MeetingQuestion.mode), isTrue);
      expect(chosen.current, MeetingQuestion.time);
    });
  });
}
