import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_flow.dart';
import 'package:momeet/shared/api/rest/export.dart';

import 'meeting_flow_test.dart' show march, ranged, upToMode;

/// 3월 [from]~[to]일(뺀 날 [excluded])
MeetingDates days(int from, int to, {List<int> excluded = const []}) =>
    MeetingDates.range(
      march(from),
      march(to),
      excluded: [for (final day in excluded) march(day)],
    );

void main() {
  group('요일별이 바꾼 기간을 기억한다', () {
    test('요일별로 바꾸면 그전 날짜(기간과 뺀 날)를 기억하고, 벗어나면 되돌린다', () {
      final daily = MeetingDraft(
        mode: MeetingMode.daily,
        dates: days(1, 4, excluded: [2]),
      );
      final weekly = daily.withMode(MeetingMode.weekly);
      expect(weekly.dates.days, days(1, 7).days);
      expect(weekly.beforeWeekly?.days, daily.dates.days);

      final back = weekly.withMode(MeetingMode.daily);
      expect(back.dates.days, daily.dates.days);
      expect(back.beforeWeekly, isNull);
    });

    test('기억한 날짜가 시간별에 맞으면 요일별인 동안에도 시간별을 고를 수 있고, 고르면 그 날짜로 돌아간다', () {
      final weekly = MeetingDraft(
        mode: MeetingMode.daily,
        dates: days(1, 3),
      ).withMode(MeetingMode.weekly);
      expect(weekly.hourlyAvailable, isTrue);

      final hourly = weekly.withMode(MeetingMode.hourly);
      expect(hourly.mode, MeetingMode.hourly);
      expect(hourly.dates.days, days(1, 3).days);
    });

    test('기억한 날짜가 시간별에 맞지 않으면 시간별은 고를 수 없고, 날짜별은 그 날짜로 돌아간다', () {
      final weekly = MeetingDraft(
        mode: MeetingMode.daily,
        dates: days(1, 10),
      ).withMode(MeetingMode.weekly);
      expect(weekly.hourlyAvailable, isFalse);
      expect(weekly.withMode(MeetingMode.hourly).mode, MeetingMode.weekly);
      expect(weekly.withMode(MeetingMode.daily).dates.days, days(1, 10).days);
    });

    test('기억한 날짜가 없으면 날짜별은 7일 그대로이고 시간별은 앞의 5일로 줄인다', () {
      final weekly = MeetingDraft(mode: MeetingMode.weekly, dates: days(1, 7));
      expect(weekly.hourlyAvailable, isTrue);
      expect(weekly.withMode(MeetingMode.daily).dates.days, days(1, 7).days);
      expect(weekly.withMode(MeetingMode.hourly).dates.days, days(1, 5).days);
    });

    test('요일별인 동안 날짜를 새로 고르면 기억을 지운다', () {
      final weekly = MeetingDraft(mode: MeetingMode.daily, dates: days(1, 3))
          .withMode(MeetingMode.weekly)
          .withDates(MeetingDates.period(march(8), 7));
      expect(weekly.beforeWeekly, isNull);
      expect(weekly.withMode(MeetingMode.hourly).dates.days, days(8, 12).days);
    });
  });

  group('질문 흐름에서 요일별을 벗어나기', () {
    test('요일별로 답한 뒤 방식을 다시 물어 시간별을 고르면 그전 기간으로 되돌리고 알린다', () {
      final flow = upToMode(
        1,
        3,
        MeetingMode.weekly,
      ).choosePublic(true).edit(MeetingQuestion.mode);
      expect(flow.draft.hourlyAvailable, isTrue);

      final hourly = flow.chooseMode(MeetingMode.hourly);
      expect(hourly.draft.mode, MeetingMode.hourly);
      expect(hourly.draft.dates.days, days(1, 3).days);
      expect(hourly.adjusted, {MeetingAdjustment.weeklyRestored});
      expect(hourly.current, MeetingQuestion.time);
    });

    test('날짜별로 벗어나도 그전 기간과 뺀 날로 되돌린다', () {
      final flow = ranged(1, 6)
          .tapDay(march(3))
          .confirmExclusions()
          .chooseMode(MeetingMode.weekly)
          .edit(MeetingQuestion.mode)
          .chooseMode(MeetingMode.daily);
      expect(flow.draft.dates.days, days(1, 6, excluded: [3]).days);
      expect(flow.adjusted, {MeetingAdjustment.weeklyRestored});
    });

    test('요일별이 되기 전에 직접 고른 7일이면 시간별은 그 7일로 판단해 고를 수 없다', () {
      final flow = upToMode(
        1,
        7,
        MeetingMode.weekly,
      ).edit(MeetingQuestion.mode);
      expect(flow.draft.hourlyAvailable, isFalse);
      expect(
        flow.chooseMode(MeetingMode.hourly).draft.mode,
        MeetingMode.weekly,
      );
    });

    test('요일별인 동안 기간을 다시 골랐으면 시간별은 앞의 5일로 줄이고 알린다', () {
      final flow = upToMode(1, 3, MeetingMode.weekly)
          .edit(MeetingQuestion.range)
          .tapDay(march(8))
          .tapDay(march(14))
          .edit(MeetingQuestion.mode)
          .chooseMode(MeetingMode.hourly);
      expect(flow.draft.mode, MeetingMode.hourly);
      expect(flow.draft.dates.days, days(8, 12).days);
      expect(flow.adjusted, {MeetingAdjustment.hourlyTrimmed});
    });
  });

  group('펼친 폼과 모임 설정에서 요일별을 벗어나기', () {
    test('기억한 날짜로 되돌리면 알린다', () {
      final flow = MeetingFlow(
        draft: MeetingDraft(mode: MeetingMode.daily, dates: days(1, 3)),
        expanded: true,
      ).changeMode(MeetingMode.weekly);
      expect(flow.adjusted, {MeetingAdjustment.weeklyPeriod});

      final back = flow.changeMode(MeetingMode.hourly);
      expect(back.draft.dates.days, days(1, 3).days);
      expect(back.adjusted, {MeetingAdjustment.weeklyRestored});
      expect(back.expanded, isTrue);
    });

    test('기억한 날짜가 없는 요일별(이미 있는 요일별 모임)을 시간별로 바꾸면 앞의 5일로 줄이고 알린다', () {
      final flow = MeetingFlow(
        draft: MeetingDraft(mode: MeetingMode.weekly, dates: days(1, 7)),
        expanded: true,
      ).changeMode(MeetingMode.hourly);
      expect(flow.draft.dates.days, days(1, 5).days);
      expect(flow.adjusted, {MeetingAdjustment.hourlyTrimmed});

      final daily = MeetingFlow(
        draft: MeetingDraft(mode: MeetingMode.weekly, dates: days(1, 7)),
        expanded: true,
      ).changeMode(MeetingMode.daily);
      expect(daily.draft.dates.days, days(1, 7).days);
      expect(daily.adjusted, isEmpty);
    });

    test('펼친 폼에서 요일별인 동안 날짜를 새로 고르면 기억을 지운다', () {
      final flow = MeetingFlow(
        draft: MeetingDraft(mode: MeetingMode.daily, dates: days(1, 3)),
        expanded: true,
      ).changeMode(MeetingMode.weekly).tapDayInForm(march(8), excluding: false);
      expect(flow.draft.beforeWeekly, isNull);
      expect(
        flow.changeMode(MeetingMode.hourly).draft.dates.days,
        days(8, 12).days,
      );
    });
  });
}
