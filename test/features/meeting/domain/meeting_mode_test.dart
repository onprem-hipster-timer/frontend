import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_grid.dart';
import 'package:momeet/shared/api/rest/export.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../meeting_fixtures.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

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
      final one = const MeetingDraft().tapDay(march(2));
      expect(roundTrip(one), MeetingMode.hourly);
      final five = [
        1,
        2,
        3,
        4,
        5,
      ].fold(const MeetingDraft(), (draft, day) => draft.tapDay(march(day)));
      expect(roundTrip(five), MeetingMode.hourly);
    });

    test('0시에 시작하는 시간별', () {
      final midnight = const MeetingDraft(startHour: 0).tapDay(march(2));
      expect(roundTrip(midnight), MeetingMode.hourly);
    });

    test('날짜별 하루·6일', () {
      final one = const MeetingDraft(mode: MeetingMode.daily).tapDay(march(2));
      expect(roundTrip(one), MeetingMode.daily);
      final six = [
        1,
        2,
        3,
        4,
        5,
        6,
      ].fold(const MeetingDraft(), (draft, day) => draft.tapDay(march(day)));
      expect(roundTrip(six), MeetingMode.daily);
    });

    test('요일별', () {
      final weekly = const MeetingDraft(
        mode: MeetingMode.weekly,
      ).tapDay(march(4));
      expect(roundTrip(weekly), MeetingMode.weekly);
    });

    test('날짜별로 기간이 7일이 되게 골라도 날짜별이다', () {
      final daily = [1, 7].fold(
        const MeetingDraft(mode: MeetingMode.daily),
        (draft, day) => draft.tapDay(march(day)),
      );
      expect(roundTrip(daily), MeetingMode.daily);
    });
  });
}
