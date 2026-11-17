import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_dates.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

/// 3월 [from]~[to]일([excluded]일 뺌)을 고른 [draft]
MeetingDraft over(
  int from,
  int to, {
  List<int> excluded = const [],
  MeetingDraft draft = const MeetingDraft(),
}) => draft.withDates(
  MeetingDates.range(
    march(from),
    march(to),
    excluded: [for (final day in excluded) march(day)],
  ),
);

/// [draft]로 만든 요청을 backend가 돌려준 모양으로 읽은 격자의 방식
MeetingMode roundTrip(MeetingDraft draft) {
  final body = draft.toMeetingCreate(title: '모임', timezone: 'Asia/Seoul');
  return MeetingGrid.of(
    makeMeeting(
      startDate: body.startDate,
      endDate: body.endDate,
      excludedDates: body.excludedDates,
      mode: body.mode,
      startTime: body.startTime,
      endTime: body.endTime,
    ),
  ).mode;
}

void main() {
  setUpAll(tz.initializeTimeZones);

  group('만든 방식이 그대로 그려진다', () {
    test('시간별 하루·5일', () {
      expect(roundTrip(over(2, 2)), MeetingMode.hourly);
      expect(roundTrip(over(1, 5)), MeetingMode.hourly);
    });

    test('7일 기간에서 가운데 이틀을 뺀 시간별', () {
      expect(roundTrip(over(4, 10, excluded: [6, 7])), MeetingMode.hourly);
    });

    test('0시에 시작하는 시간별', () {
      expect(
        roundTrip(over(2, 2, draft: const MeetingDraft(startHour: 0))),
        MeetingMode.hourly,
      );
    });

    test('날짜별 하루·6일', () {
      const daily = MeetingDraft(mode: MeetingMode.daily);
      expect(roundTrip(over(2, 2, draft: daily)), MeetingMode.daily);
      expect(roundTrip(over(1, 6, draft: daily)), MeetingMode.daily);
    });

    test('요일별', () {
      expect(
        roundTrip(over(4, 4).withMode(MeetingMode.weekly)),
        MeetingMode.weekly,
      );
    });

    test('날짜별로 기간이 7일이 되게 골라도 날짜별이다', () {
      expect(
        roundTrip(
          over(1, 7, draft: const MeetingDraft(mode: MeetingMode.daily)),
        ),
        MeetingMode.daily,
      );
    });
  });
}
