import 'package:flutter_test/flutter_test.dart';
import 'package:momeet/features/meeting/domain/meeting_draft.dart';
import 'package:momeet/features/meeting/domain/meeting_mode.dart';
import 'package:momeet/shared/api/rest/export.dart';

import '../meeting_fixtures.dart';

/// 2027년 3월의 [day]일 (3월 1일은 월요일)
DateTime march(int day) => DateTime.utc(2027, 3, day);

/// [draft]로 만든 요청을 backend가 돌려준 모양으로 읽는다
MeetingRead roundTrip(MeetingDraft draft) {
  final body = draft.toMeetingCreate(title: '모임', timezone: 'Asia/Seoul');
  return makeMeeting(
    startDate: body.startDate,
    endDate: body.endDate,
    availableDays: body.availableDays,
    startTime: body.startTime,
    endTime: body.endTime,
  );
}

void main() {
  group('값에서 방식 읽기', () {
    test('0시가 아닌 시각에 시작하면 시간별이다', () {
      expect(
        inferMeetingMode(makeMeeting(startTime: '06:00:00')),
        MeetingMode.hourly,
      );
      expect(
        inferMeetingMode(makeMeeting(startTime: '00:30:00')),
        MeetingMode.hourly,
      );
    });

    test('0시에 시작하고 기간이 7일이면 요일별이다', () {
      expect(
        inferMeetingMode(
          makeMeeting(
            startDate: march(1),
            endDate: march(7),
            startTime: '00:00:00',
            endTime: '00:00:00',
          ),
        ),
        MeetingMode.weekly,
      );
    });

    test('0시에 시작하고 기간이 7일이 아니면 날짜별이다', () {
      for (final last in [1, 6, 8, 31]) {
        expect(
          inferMeetingMode(
            makeMeeting(
              startDate: march(1),
              endDate: march(last),
              startTime: '00:00:00',
              endTime: '00:00:00',
            ),
          ),
          MeetingMode.daily,
          reason: '3월 1일~$last일',
        );
      }
    });

    test('시각은 초가 없어도 읽는다', () {
      expect(isMidnight('00:00'), isTrue);
      expect(isMidnight('00:00:00'), isTrue);
      expect(isMidnight('06:00'), isFalse);
    });

    test('로컬 자정으로 읽은 날짜도 날짜로 센다', () {
      final meeting = makeMeeting(
        startDate: DateTime(2027, 3, 10),
        endDate: DateTime(2027, 3, 16),
        startTime: '00:00:00',
        endTime: '00:00:00',
      );
      expect(inferMeetingMode(meeting), MeetingMode.weekly);
    });
  });

  group('만든 방식이 그대로 읽힌다', () {
    test('시간별 하루·5일', () {
      final one = const MeetingDraft().tapDay(march(2));
      expect(inferMeetingMode(roundTrip(one)), MeetingMode.hourly);
      final five = [
        1,
        2,
        3,
        4,
        5,
      ].fold(const MeetingDraft(), (draft, day) => draft.tapDay(march(day)));
      expect(inferMeetingMode(roundTrip(five)), MeetingMode.hourly);
    });

    test('날짜별 하루·6일', () {
      final one = const MeetingDraft(mode: MeetingMode.daily).tapDay(march(2));
      expect(inferMeetingMode(roundTrip(one)), MeetingMode.daily);
      final six = [
        1,
        2,
        3,
        4,
        5,
        6,
      ].fold(const MeetingDraft(), (draft, day) => draft.tapDay(march(day)));
      expect(inferMeetingMode(roundTrip(six)), MeetingMode.daily);
    });

    test('요일별', () {
      final weekly = const MeetingDraft(
        mode: MeetingMode.weekly,
      ).tapDay(march(4));
      expect(inferMeetingMode(roundTrip(weekly)), MeetingMode.weekly);
    });

    test('날짜별로 기간이 7일이 되게 고르면 값이 요일별과 같아 요일별로 읽힌다', () {
      final daily = [1, 7].fold(
        const MeetingDraft(mode: MeetingMode.daily),
        (draft, day) => draft.tapDay(march(day)),
      );
      expect(daily.mode, MeetingMode.daily);
      expect(inferMeetingMode(roundTrip(daily)), MeetingMode.weekly);
    });
  });

  test('시간별 시작 시각의 하한은 0시보다 늦다', () {
    expect(hourlyEarliestHour, greaterThan(0));
    expect(const MeetingDraft().startHour, hourlyEarliestHour);
  });
}
